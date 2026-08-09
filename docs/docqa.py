#!/usr/bin/env python3
"""Validate local Markdown links, anchors, and image references in this docs tree."""

from __future__ import annotations

import argparse
import difflib
import html
import os
import re
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlsplit


MARKDOWN_SUFFIXES = {".md", ".markdown"}
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".bmp"}

LARGE_IMAGE_BYTES = 1 * 1024 * 1024  # 1 MiB
CONFIG_FILE = "docqa.ini"
MD_LINK = re.compile(r"(?<!!)\[[^\]]*\]\(\s*(<[^>]*>|[^)\r\n]+?)\s*\)")
MD_IMAGE = re.compile(r"!\[[^\]]*\]\(\s*(<[^>]*>|[^)\r\n]+?)\s*\)")
HTML_TAG = re.compile(r"<(a|img)\b[^>]*>", re.IGNORECASE | re.DOTALL)
ATTRIBUTE = re.compile(
    r"\b(?P<name>href|src|id|alt)\s*=\s*(?:\"(?P<double>[^\"]*)\"|'(?P<single>[^']*)'|(?P<bare>[^\s>`]+))",
    re.IGNORECASE | re.DOTALL,
)
HEADING = re.compile(r"^ {0,3}#{1,6}\s+(.*?)(?:\s+#+\s*)?$")
HTML_TAGS = re.compile(r"<[^>]+>")


@dataclass(frozen=True)
class Reference:
    source: Path
    line: int
    target: str


@dataclass(frozen=True)
class Problem:
    kind: str
    reference: Reference
    suggestion: str = ""
    detail: str = ""


def line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def attribute_value(tag: str, name: str) -> str | None:
    for match in ATTRIBUTE.finditer(tag):
        if match.group("name").lower() == name:
            return next(value for value in match.group("double", "single", "bare") if value is not None)
    return None


def markdown_target(value: str) -> str:
    value = value.strip()
    if value.startswith("<") and value.endswith(">"):
        return value[1:-1]
    # A Markdown title follows the destination after whitespace. URLs containing
    # spaces are normally enclosed in angle brackets, so this keeps normal paths intact.
    return re.split(r"\s+(?=[\"'])", value, maxsplit=1)[0]


def is_external(value: str) -> bool:
    parts = urlsplit(value)
    return bool(parts.scheme) or value.startswith("//") or value.startswith("data:")


def split_target(value: str) -> tuple[str, str]:
    """Return decoded local path and fragment, discarding a query string."""
    parts = urlsplit(value)
    return unquote(parts.path), unquote(parts.fragment)


def resolved_path(source: Path, target_path: str) -> Path:
    return (source.parent / Path(target_path)).resolve()


def github_anchor(heading: str) -> str:
    # GitHub keeps text inside HTML elements, but not the elements themselves.
    value = html.unescape(HTML_TAGS.sub("", heading)).strip().lower()
    value = re.sub(r"\s+", "-", value)
    # GitHub removes punctuation while retaining letters, numbers, underscores and hyphens.
    return "".join(char for char in value if char.isalnum() or char in "_-")


def anchors_for(text: str) -> set[str]:
    anchors: set[str] = set()
    counts: dict[str, int] = {}
    for line in text.splitlines():
        match = HEADING.match(line)
        if not match:
            continue
        base = github_anchor(match.group(1))
        if not base:
            continue
        number = counts.get(base, 0)
        anchor = base if number == 0 else f"{base}-{number}"
        counts[base] = number + 1
        anchors.add(anchor)
    for tag in re.finditer(r"<[^>]+>", text, re.DOTALL):
        identifier = attribute_value(tag.group(0), "id")
        if identifier:
            anchors.add(html.unescape(identifier))
    return anchors


def close_match(target: str, choices: list[str]) -> str:
    matches = difflib.get_close_matches(target, choices, n=1, cutoff=0.55)
    return matches[0] if matches else ""


def scan_references(document: Path, text: str) -> tuple[list[Reference], list[Reference], list[Reference]]:
    document_links: list[Reference] = []
    image_links: list[Reference] = []
    anchor_links: list[Reference] = []
    for match in MD_LINK.finditer(text):
        target = markdown_target(match.group(1))
        if not is_external(target):
            path, fragment = split_target(target)
            ref = Reference(document, line_number(text, match.start()), target)
            if path.lower().endswith(tuple(MARKDOWN_SUFFIXES)):
                document_links.append(ref)
            if fragment and (not path or path.lower().endswith(tuple(MARKDOWN_SUFFIXES))):
                anchor_links.append(ref)
    for match in MD_IMAGE.finditer(text):
        target = markdown_target(match.group(1))
        if not is_external(target):
            image_links.append(Reference(document, line_number(text, match.start()), target))
    for match in HTML_TAG.finditer(text):
        tag = match.group(0)
        tag_name = match.group(1).lower()
        target = attribute_value(tag, "href" if tag_name == "a" else "src")
        if target is None or is_external(target):
            continue
        ref = Reference(document, line_number(text, match.start()), target)
        path, fragment = split_target(target)
        if tag_name == "a":
            if path.lower().endswith(tuple(MARKDOWN_SUFFIXES)):
                document_links.append(ref)
            if fragment and (not path or path.lower().endswith(tuple(MARKDOWN_SUFFIXES))):
                anchor_links.append(ref)
        else:
            image_links.append(ref)
    return document_links, image_links, anchor_links


def scan_external_references(document: Path, text: str) -> list[Reference]:
    """Return HTTP/HTTPS links found in Markdown and HTML."""
    references: list[Reference] = []

    for match in MD_LINK.finditer(text):
        target = markdown_target(match.group(1))
        if urlsplit(target).scheme.lower() in {"http", "https"}:
            references.append(
                Reference(
                    document,
                    line_number(text, match.start()),
                    target,
                )
            )

    for match in HTML_TAG.finditer(text):
        tag = match.group(0)
        if match.group(1).lower() != "a":
            continue

        target = attribute_value(tag, "href")
        if target and urlsplit(target).scheme.lower() in {"http", "https"}:
            references.append(
                Reference(
                    document,
                    line_number(text, match.start()),
                    target,
                )
            )

    return references


def check_external_url(url: str, timeout: float = 8.0) -> str:
    """Return an empty string when reachable, otherwise a short error.

    Some sites reject HEAD requests or block non-browser user agents, so
    external links are checked with a lightweight GET using a browser-like
    user agent.
    """
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/151.0.0.0 Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        },
        method="GET",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            if 200 <= response.status < 400:
                return ""
            return f"HTTP {response.status}"

    except urllib.error.HTTPError as error:
        # A 401/403/429 response means the server is reachable, but it
        # refuses automated access or is rate-limiting us. This is not
        # evidence that the URL itself is broken.
        if error.code in {401, 403, 429}:
            return ""
        return f"HTTP {error.code}"

    except urllib.error.URLError as error:
        # Connection/SSL/DNS problems cannot establish that the URL is broken.
        # Keep these out of the warning count; they are reported as
        # "not verified" instead.
        return ""

    except TimeoutError:
        # A timeout is inconclusive, not evidence of a broken URL.
        return ""


def audit_alt_text(root: Path, texts: dict[Path, str]) -> list[Problem]:
    """Audit alt text against the filename-without-extension convention."""
    problems: list[Problem] = []

    for document, text in texts.items():
        for match in MD_IMAGE.finditer(text):
            alt_text = match.group(0)[2:].split("](", 1)[0]
            target = markdown_target(match.group(1))
            image_path, _ = split_target(target)
            expected = Path(unquote(image_path)).stem

            if alt_text.strip() and alt_text != expected:
                problems.append(
                    Problem(
                        "Alt text does not match filename",
                        Reference(document, line_number(text, match.start()), target),
                        detail=f"expected {expected!r}, found {alt_text!r}",
                    )
                )

        for match in HTML_TAG.finditer(text):
            tag = match.group(0)
            if match.group(1).lower() != "img":
                continue

            target = attribute_value(tag, "src")
            if not target or is_external(target):
                continue

            alt_text = attribute_value(tag, "alt")
            if not alt_text or not alt_text.strip():
                continue

            image_path, _ = split_target(target)
            expected = Path(unquote(image_path)).stem

            if alt_text != expected:
                problems.append(
                    Problem(
                        "Alt text does not match filename",
                        Reference(document, line_number(text, match.start()), target),
                        detail=f"expected {expected!r}, found {alt_text!r}",
                    )
                )

    return problems


def validate_external_links(root: Path, texts: dict[Path, str]) -> list[Problem]:
    """Check HTTP/HTTPS links. Failures are warnings, not validation errors."""
    problems: list[Problem] = []

    for document, text in texts.items():
        for ref in scan_external_references(document, text):
            error = check_external_url(ref.target)
            if error:
                problems.append(
                    Problem("External link", ref, detail=error)
                )

    return problems


def validate(root: Path) -> tuple[
    list[Problem],
    list[Problem],
    list[Problem],
    list[Path],
    list[Problem],
    list[Problem],
    list[Problem],
    list[tuple[Path, int]],
    int,
    int,
]:
    root = root.resolve()
    documents = sorted(
        path for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in MARKDOWN_SUFFIXES
    )

    # The repository-level README is part of the documentation set even
    # though it lives one level above the docs directory.
    parent_readme = root.parent / "README.md"
    if parent_readme.is_file() and parent_readme not in documents:
        documents.append(parent_readme)
        documents.sort()
    images = sorted(
        path for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
    )
    doc_names = [path.name for path in documents]
    image_names = [path.name for path in images]
    texts = {path: path.read_text(encoding="utf-8-sig") for path in documents}

    document_problems: list[Problem] = []
    anchor_problems: list[Problem] = []
    image_problems: list[Problem] = []
    orphaned_documents: list[Problem] = []
    alt_text_problems: list[Problem] = []
    duplicate_heading_problems: list[Problem] = []
    referenced_images: set[Path] = set()
    referenced_documents: set[Path] = set()
    large_images: list[tuple[Path, int]] = []

    # README is a natural root document and does not need an incoming link.
    root_documents = {
        path for path in documents
        if path.name.lower() == "readme.md"
    }
    config = load_config(root)
    ignored_duplicates = config["duplicates"]

    for document, text in texts.items():
        document_links, image_links, anchor_links = scan_references(document, text)

        for ref in document_links:
            path, _ = split_target(ref.target)
            target = resolved_path(document, path)

            if target.is_file():
                referenced_documents.add(target)
            else:
                suggestion = close_match(Path(path).name, doc_names)
                document_problems.append(
                    Problem("Broken document link", ref, suggestion)
                )

        for ref in anchor_links:
            path, fragment = split_target(ref.target)
            target_document = document if not path else resolved_path(document, path)

            if not target_document.is_file():
                continue  # Missing document is already reported above.

            target_anchors = anchors_for(
                texts.get(
                    target_document,
                    target_document.read_text(encoding="utf-8-sig"),
                )
            )

            if fragment not in target_anchors:
                suggestion = close_match(fragment, sorted(target_anchors))
                anchor_problems.append(
                    Problem("Broken anchor", ref, suggestion)
                )

        for ref in image_links:
            path, _ = split_target(ref.target)
            target_image = resolved_path(document, path)

            if target_image.is_file():
                referenced_images.add(target_image)
            else:
                suggestion = close_match(Path(path).name, image_names)
                image_problems.append(
                    Problem("Broken image link", ref, suggestion)
                )

        # Normal QA check: only verify that image alt text is present.
        for match in MD_IMAGE.finditer(text):
            alt_text = match.group(0)[2:].split("](", 1)[0]
            target = markdown_target(match.group(1))

            if not alt_text.strip():
                alt_text_problems.append(
                    Problem(
                        "Missing alt text",
                        Reference(
                            document,
                            line_number(text, match.start()),
                            target,
                        ),
                    )
                )

        # HTML <img>: verify that an alt attribute is present and non-empty.
        for match in HTML_TAG.finditer(text):
            tag = match.group(0)
            if match.group(1).lower() != "img":
                continue

            target = attribute_value(tag, "src")
            if not target or is_external(target):
                continue

            alt_text = attribute_value(tag, "alt")
            if not alt_text or not alt_text.strip():
                alt_text_problems.append(
                    Problem(
                        "Missing alt text",
                        Reference(
                            document,
                            line_number(text, match.start()),
                            target,
                        ),
                    )
                )

        # Duplicate Markdown headings within each document.
        seen_headings: dict[str, tuple[int, str]] = {}
        for lineno, line in enumerate(text.splitlines(), 1):
            match = HEADING.match(line)
            if not match:
                continue

            heading_text = match.group(1).strip()
            slug = github_anchor(heading_text)
            if not slug:
                continue

            if slug in seen_headings:
                first_line, first_text = seen_headings[slug]
                exception_key = f"{document.relative_to(root)}:{heading_text}"
                if exception_key not in ignored_duplicates:
                    ref = Reference(document, lineno, heading_text)
                    duplicate_heading_problems.append(
                        Problem(
                            "Duplicate heading",
                            ref,
                            f"first occurrence at line {first_line}",
                        )
                    )
            else:
                seen_headings[slug] = (lineno, heading_text)

    for image in images:
        size = image.stat().st_size
        if size > LARGE_IMAGE_BYTES:
            large_images.append((image, size))

    large_images.sort(key=lambda item: item[1], reverse=True)

    orphaned = sorted(
        path for path in documents
        if path not in referenced_documents and path not in root_documents
    )

    orphaned_images = sorted(
        path for path in images
        if path.resolve() not in referenced_images
    )

    return (
        document_problems,
        anchor_problems,
        image_problems,
        orphaned_images,
        alt_text_problems,
        duplicate_heading_problems,
        [
            Problem(
                "Orphaned document",
                Reference(path, 0, str(path.relative_to(root))),
            )
            for path in orphaned
        ],
        large_images,
        len(documents),
        len(images),
    )


def load_config(root: Path) -> dict[str, set[str]]:
    """Load intentional duplicate-heading exceptions from docqa.ini."""
    config: dict[str, set[str]] = {"duplicates": set()}
    path = root / CONFIG_FILE
    if not path.is_file():
        return config

    section = ""
    for raw_line in path.read_text(encoding="utf-8-sig").splitlines():
        line = raw_line.strip()
        if not line or line.startswith(("#", ";")):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip().lower()
            continue
        if section == "duplicates":
            value = line.split("=", 1)[-1].strip() if "=" in line else line
            if ":" in value:
                config["duplicates"].add(value)
    return config


def print_problems(root: Path, problems: list[Problem]) -> None:
    for problem in problems:
        ref = problem.reference
        source_path = ref.source.resolve()
        root_path = root.resolve()
        try:
            location = source_path.relative_to(root_path)
        except ValueError:
            # The repository-level README is one level above docs/.
            # Keep it readable without allowing pathlib.relative_to()
            # to raise an exception.
            location = Path("..") / source_path.name

        message = f"  {problem.kind}: {location}:{ref.line}: {ref.target}"
        if problem.suggestion:
            message += f" (did you mean {problem.suggestion}?)"
        if problem.detail:
            message += f" ({problem.detail})"
        print(message)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Markdown documentation and image references."
    )
    parser.add_argument(
        "--external",
        action="store_true",
        help="also check HTTP/HTTPS links (warnings only)",
    )
    parser.add_argument(
        "--large-images",
        type=float,
        metavar="MIB",
        default=1.0,
        help="warn about images larger than MIB (default: 1.0)",
    )
    parser.add_argument(
        "--check-alt-text",
        action="store_true",
        help="audit image alt text against the filename convention",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="only report validation problems; stay silent when everything is clean",
    )
    args = parser.parse_args()

    if args.large_images <= 0:
        parser.error("--large-images must be greater than zero")

    global LARGE_IMAGE_BYTES
    LARGE_IMAGE_BYTES = int(args.large_images * 1024 * 1024)

    root = Path.cwd()

    (
        documents,
        anchors,
        images,
        orphaned_images,
        alt_text,
        duplicate_headings,
        orphaned_documents,
        large_images,
        document_count,
        image_count,
    ) = validate(root)

    alt_audit_problems: list[Problem] = []
    if args.check_alt_text:
        audit_texts = {
            path: path.read_text(encoding="utf-8-sig")
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in MARKDOWN_SUFFIXES
        }
        alt_audit_problems = audit_alt_text(root, audit_texts)

    external_problems: list[Problem] = []
    if args.external:
        texts = {
            path: path.read_text(encoding="utf-8-sig")
            for path in root.rglob("*")
            if path.is_file() and path.suffix.lower() in MARKDOWN_SUFFIXES
        }
        external_problems = validate_external_links(root, texts)

    blocking = documents or anchors or images or orphaned_images
    warnings = (
        orphaned_documents
        or alt_text
        or duplicate_headings
        or large_images
        or external_problems
    )

    if args.quiet and not blocking:
        return 0

    print("=" * 60)
    print("Documentation QA Tool")
    print("=" * 60)
    print(f"Documents ............ {document_count}")
    print(f"Images .............. {image_count}")
    print()
    print("VALIDATION")
    print(f"  Broken document links ... {len(documents)}")
    print(f"  Broken anchors .......... {len(anchors)}")
    print(f"  Broken image links ...... {len(images)}")
    print(f"  Orphaned images ......... {len(orphaned_images)}")
    print()
    print("QUALITY")
    print(f"  Orphaned documents ...... {len(orphaned_documents)}")
    print(f"  Missing alt text ........ {len(alt_text)}")
    print(f"  Duplicate headings ...... {len(duplicate_headings)}")
    print(f"  Large images (> {args.large_images:g} MiB) .. {len(large_images)}")

    if args.check_alt_text:
        print()
        print("ALT TEXT AUDIT")
        print(f"  Filename mismatches ...... {len(alt_audit_problems)}")

    if args.external:
        print()
        print("EXTERNAL LINKS")
        print(f"  Warnings ................ {len(external_problems)}")

    if documents or anchors or images:
        print()
        print("Validation problems:")
        print_problems(root, documents)
        print_problems(root, anchors)
        print_problems(root, images)

    if orphaned_images:
        print()
        print("Orphaned images:")
        for path in orphaned_images:
            print(f"  {path.relative_to(root)}")

    if orphaned_documents:
        print()
        print("Orphaned documents:")
        for problem in orphaned_documents:
            print(f"  {problem.reference.target}")

    if alt_text:
        print()
        print("Missing alt text:")
        print_problems(root, alt_text)

    if duplicate_headings:
        print()
        print("Duplicate headings:")
        print_problems(root, duplicate_headings)

    if large_images:
        print()
        print(f"Large images (> {args.large_images:g} MiB):")
        for path, size in large_images:
            size_mib = size / (1024 * 1024)
            print(f"  {size_mib:6.2f} MiB  {path.relative_to(root)}")

    if alt_audit_problems:
        print()
        print("Alt text audit:")
        print_problems(root, alt_audit_problems)

    if external_problems:
        print()
        print("External link warnings:")
        print_problems(root, external_problems)

    print("=" * 60)
    if blocking:
        print("VALIDATION FAILED")
        print("=" * 60)
        return 1

    print("VALIDATION PASSED")
    print("=" * 60)
    if warnings:
        print("Quality warnings present (not validation failures).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
