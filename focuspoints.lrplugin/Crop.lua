--[[----------------------------------------------------------------------------
  Crop.lua
  Copyright John R. Ellis  https://johnrellis.com/lightroom/allplugins.htm

  Purpose of this module:
  Helper functions to straighten images:
  - Get crop of a photo
  - Adjust angle for a photo (maintain its aspect ratio)
  - Apply crop to a photo
  - Reset crop of a photo

  This module (which is part of AnyCrop plugin) has been streamlined and
  adapted to the specific requirements of 'Straighten Images'.

  LrDevelopController is not used in particular because it conflicts with
  the AutoSync setting when multiple photos are selected for straightening.

------------------------------------------------------------------------------]]

--[[------------------------------------------------------------------------

Coordinate Systems

There are three different coordinate systems used here.

Develop Settings:

LR represents a crop with the photo:getDevelopSettings() values CropLeft,
CropRight, CropTop, and CropBottom, each in [0..1], and CropAngle, the
angle of the crop in degrees, in [-45..45].   The upper-left corner of the
photo is (0, 0) and the lower-right (1, 1). The coordinates are relative to
the original photo with no mirroring or rotation applied.

The upper-left corner of the crop is (CropLeft, CropTop) and the lower-
right is (CropRight, CropBottom).  The angle represents the degrees
clockwise (positive) or counterclockwise (negative) that the rectangle is
rotated around its center.

Photo Coordinates:

This module translates the develop-setting coordinates into "photo
coordinates" (x, y), where x is in [0..w] and y is in [0..h], with the
lower-left corner of the photo is (0, 0), and the photo has pixel
dimensions w x h. These coordinates are relative to the original photo with
no mirroring or rotation applied.  

The angle is in [-45..45] and represents the degrees counterclockwise
(positive) or clockwise (negative) the rectangle is rotated around its
center.

Visible Coordinates:

Visible coordinates are relative to what the user sees in the Develop
module, after mirroring and rotation have been applied.  The x coordinate
is in [0..w] and y is in [0..h], and the lower-left corner is (0, 0).

The angle is in [-45..45] and represents the degrees counterclockwise
(positive) or clockwise (negative) the rectangle is rotated around its
center.  

Translating photo coordinates to visible coordinates involves interpreting
the "orientation" getDevelopSettings() value, which represents the
mirroring and rotation the user has applied to the photo.

Note About Super Resolution:

Photo Coordinates and Visible Coordinates are relative to the original
resolution of the photo, even if Super Resolution has been applied (which
doubles the rendered resolution in each dimension).

--------------------------------------------------------------------------
Crop

A crop is represented as a table with these fields:

number opw, oph
    The photo width and height (original photo coordinates)
string orientation
    The photo's orientation
number pw, ph
    The photo width and height (visible coordinates) 
Point center
    The center of the crop (visible coordinates)
Number a
    Angle of the crop in degrees (visible coordinates)
Number w, h
    Width and height of the crop (visible coordinates)
number sw, sh
    The width and height of the crop (visible coordinates), in terms of
    Super Resolution if that was applied, or original resolution if not.
Boolean locked
    Current setting of the crop lock constraining aspect ratio

--------------------------------------------------------------------------
Preset

A crop preset is a table with these fields:

string title 
    The name assigned to the preset by the user.

number width, height
    The aspect ratio of the crop, in arbitrary units

bool useOriginalRatio
    If true, the width and height of the preset are ignored, and the 
    aspect ratio of the photo to which the preset is being applied 
    is used.

string applyAngle: "NoRotation", "Angle", "Exact"
number angle: 
    NoRotation: The resulting crop will have the same angle as the current
        crop.
    Angle: The resulting crop will have rotation of "angle" addeded to 
        the current crop's rotation.
    Exact: The result crop will have rotation "angle".
    
string orientation: "Match" or "AsSpecified"
    If "Match", then the resulting crop will have the same landscape/
    portrait orientation as the current crop of the image. Otherwise,
    it will have the orientation as specified by the width x height 
    of the preset.
    
string position: "Centered", "Relative", "Exact"
number positionX positionY 
    Centered: the crop will be centered in the current crop of the image.
    Relative: the crop will be centered around (positionX, positionY), which
        is in ([0..1], [0..1]), representing the relative position of the crop
        in the image, regardless of the image's actual size.
    Exact: the crop will be centered at visible coordinates (positionX,
        positionY) within the photo, not the current crop

string size : "FitInPhoto", "FitInside", "FitOutside", "SamePixels", 
    "Proportion", "Exact"
number sizeProportion 
    FitInPhoto: the crop is made as large as possible within the image
    FitInside: the crop is made as large as possible within the image's 
        current crop.
    FitOutside: the crop is made just large enough to fit outside the
        image's current crop.
    SamePixels: the crop is sized to have the same number of pixels as 
        the image's current crop.
    Proportion: the crop is sized to be sizeProportion * the pixels of 
        the image's current crop, where sizeProportion is in [0..1].
    Exact: the crop is sized to be exactly width x height pixels.

    In the first four options, if the resulting crop doesn't fit inside the
    original image, then it is sized smaller so that it just fits. With
    Exact, if the crop doesn't fit in the image, a user-visible error
    results.

bool openCropTool
    Opens the Crop tool in Develop after applying the preset to the most-
    selected photo.

integer menuShortcut (nil or >= 1)
    The index of the menu shortcut assigned to this preset, or nil if no 
    shortcut is assigned.

------------------------------------------------------------------------------]]

local Crop = {}

local LrApplication = import "LrApplication"
local LrTasks = import  'LrTasks'

local abs = math.abs
local cos = math.cos
local max = math.max
local min = math.min
local rad = math.rad
local shallowcopy = table.shallowcopy
local sin = math.sin
local sqrt = math.sqrt

local version = LrApplication.versionTable ()
local V143Bug = version.major == 14 and version.minor == 3 and 
    version.revision == 0
    --[[ True if we should apply the fix for the negative-crop-angle bug 
    in LR 14.3 that was fixed in LR 14.3.1 ]]

    -- Forward references
local angleFromVisible, angleToVisible, photoSetDevelopCrop, pAdd,
    pCen, pDist, pointFromVisible, pMul, pRot, pSub, pointToVisible

--[[----------------------------------------------------------------------------
public void
photoReset (LrPhoto photo)

Resets the crop of "photo" to be the entire photo with no angle.  It is the
caller's responsibility to wrap the call with catalog:withWriteAccessDo()
if not currently in Develop.
------------------------------------------------------------------------------]]

function Crop.photoReset (photo, title)
    photoSetDevelopCrop (photo, 0, 0, 1, 0, 1, title)
    end    

--[[----------------------------------------------------------------------------
public Crop
ofPhoto (LrPhoto photo)

Returns the current crop of "photo" as a Crop record.

Returns nil if "photo" is nil or a video.
------------------------------------------------------------------------------]]

function Crop.ofPhoto (photo)
    local s = Crop.photoSettings (photo)
    if s == nil then return nil end

    local c1 = {x = s.cropLeft * s.pw, y = (1 - s.cropTop) * s.ph}
    local c2 = {x = s.cropRight * s.pw, y = (1 - s.cropBottom) * s.ph}

    local dims = pointToVisible ({x = s.pw, y = s.ph}, s.orientation, 0, 0)
    local pwv, phv = abs (dims.x), abs (dims.y)
    local av = angleToVisible (s.angle, s.orientation)
    local c1v = pointToVisible (c1, s.orientation, pwv, phv)
    local c2v = pointToVisible (c2, s.orientation, pwv, phv)

    local cv = pCen (c1v, c2v)
    local c1vr = pRot (c1v, cv, -av)
    local c2vr = pRot (c2v, cv, -av)
    local wv, hv = abs (c2vr.x - c1vr.x), abs (c2vr.y - c1vr.y)

    local sr = s.superResolution and 2 or 1

    local crop = {center = cv, a = av, w = wv, h = hv, sw = wv * sr, 
        sh = hv * sr, pw = pwv, ph = phv, opw = s.pw, oph = s.ph, 
        orientation = s.orientation, locked = s.locked}
    return crop
    end  

--[[----------------------------------------------------------------------------
public Crop
apply (Crop crop, LrPhoto photo [, string title])

Applies "crop" to "photo" and returns Crop. It "title" is non-nil, it 
will appear in Develop History.

It is the caller's responsibility to wrap the call with
catalog:withWriteAccessDo() if not currently in Develop.
------------------------------------------------------------------------------]]

function Crop.apply (crop, photo, title)

        --[[ Convert to LR settings ]]
    local clr = pointFromVisible (
        crop.center, crop.orientation, crop.pw, crop.ph)
    local alr = angleFromVisible (crop.a, crop.orientation)
    local dims = pointFromVisible (
        {x = crop.w, y = crop.h}, crop.orientation, 0, 0)
    local wp, hp = abs (dims.x), abs (dims.y)

    local rul = pAdd (clr, {x = -wp / 2, y = hp / 2})
    local rlr = pAdd (clr, {x = wp / 2, y = -hp / 2})
    local ul = pRot (rul, clr, alr)
    local lr = pRot (rlr, clr, alr)

    local cropLeft = max (0, min (1, ul.x / crop.opw))
    local cropRight = max (0, min (1, lr.x / crop.opw))
    local cropTop = max (0, min (1, 1 - ul.y / crop.oph))
    local cropBottom = max (0, min (1, 1 - lr.y / crop.oph))

        --[[ Set the crop settings ]]
    photoSetDevelopCrop (photo, alr, cropLeft, cropRight, cropTop, cropBottom,
        title)

    return crop
    end

--[[----------------------------------------------------------------------------
public table
photoSettings (LrPhoto photo)

Returns fields representing all the crop information for the photo:

    pw, ph, orientation, cropLeft, cropRight, cropTop, cropBottom, angle,
        locked, superResolution

If photo is nil, a video, missing, or corrupt, returns nil.

There's an obscure race where if the user deletes the current photo,
photo:getRawMetadata() throws an error (attempt to index nil).  Most
recently in 2022, it occurred when Cosimo did Ctrl+Backspace (delete
rejected photos). We log the error and return nil.
------------------------------------------------------------------------------]]

local function photoSettings (photo)
    if photo == nil then return nil end

      local function hasSuperResolution(photo)

        local settings = photo:getDevelopSettings()
        local fl = settings.FilterList
        if not (fl and fl.Filters) then return false end

        for _, f in ipairs(fl.Filters) do

            if f.Name == "Enhance" then
                if f.Title and f.Title:find("SuperRes") then
                    return true
                end

                -- fallback: resolution doubling check
                if f.SrcBoundsRight and f.DstBoundsRight then
                    if f.DstBoundsRight >= f.SrcBoundsRight * 2 then
                        return true
                    end
                end
            end

        end
        return false
    end

    local s = {}

    s.pw = photo:getRawMetadata ("width")
    s.ph = photo:getRawMetadata ("height")
    local d = photo:getDevelopSettings ()
    if not (d.orientation and d.CropLeft and d.CropRight and d.CropTop and
        d.CropBottom and d.CropAngle)
    then
            -- Missing and corrupt photos sometimes don't have these settings.
        return nil
        end
    s.superResolution = hasSuperResolution (photo)
    s.orientation = d.orientation
    s.cropLeft = d.CropLeft
    s.cropRight = d.CropRight
    s.cropTop = d.CropTop
    s.cropBottom = d.CropBottom
    s.angle = - d.CropAngle
    s.locked = d.CropConstrainAspectRatio or true
    return s
    end

function Crop.photoSettings (photo)
    local success, result = LrTasks.pcall (photoSettings, photo)
    if not success then 
        return nil
    else
        return result
        end
    end

function Crop.adjustAngle (crop, amount)
    local pw, ph, w, h, a, center = 
        crop.pw, crop.ph, crop.w, crop.h, crop.a, crop.center
    a = max (-45, min (45, a + amount))

        --[[ Compute the four corners ]]
    local ul = pRot (pAdd (center, p (-w / 2,  h / 2)), center, a)
    local ur = pRot (pAdd (center, p ( w / 2,  h / 2)), center, a)
    local ll = pRot (pAdd (center, p (-w / 2, -h / 2)), center, a)
    local lr = pRot (pAdd (center, p ( w / 2, -h / 2)), center, a)

        --[[ Find the bounding rectangle ]]
    local llBR = p (min (ul.x, ll.x), min (ll.y, lr.y))
    local urBR = p (max (lr.x, ur.x), max (ur.y, ul.y))
    local dims = p (urBR.x - llBR.x, urBR.y - llBR.y)

        --[[ Shrink the bounding rectangle to fit within photo, possibly by
        shifting the center ]]
    local shrink = min (1, crop.pw / dims.x, crop.ph / dims.y)
    dims = pMul (dims, shrink)
    llBR = pAdd (center, p (-dims.x / 2, -dims.y / 2))
    urBR = pAdd (center, p ( dims.x / 2,  dims.y / 2))

        --[[ Shift the center so the bounding rectangle fits in the photo ]]
    local shift = p (
        llBR.x < 0 and -llBR.x or pw < urBR.x and pw - urBR.x or 0,
        llBR.y < 0 and -llBR.y or ph < urBR.y and ph - urBR.y or 0)

        --[[ Shrink and shift the new crop ]]
    local newCrop = shallowcopy (crop)
    newCrop.a, newCrop.w, newCrop.h = a, shrink * w, shrink * h
    newCrop.center = pAdd (center, shift)

    return newCrop
    end

--[[----------------------------------------------------------------------------
private void
photoSetDevelopCrop (LrPhoto photo, number angle, number cropleft, 
    number cropRight, number cropTop, number cropBottom [, string title])

Sets the low level Develop crop settings.

It "title" is non-nil, then it will appear in Develop History (via
photo:applyDevelopPreset() always being used).

It is the caller's responsibility to wrap the call with
catalog:withWriteAccessDo() if not currently in Develop.
------------------------------------------------------------------------------]]

function photoSetDevelopCrop (photo, angle, cropLeft, cropRight, cropTop, cropBottom, title)

    local settings = {}
    settings.CropLeft = cropLeft
    settings.CropRight = cropRight
    settings.CropTop = cropTop
    settings.CropBottom = cropBottom
    settings.CropAngle = - angle
    if V143Bug then
        settings.CropConstrainToUnitSquare = angle < 0 and 0 or 1
        if angle < 0 then settings.CropConstrainToWarp = 1 end
        end

    photo:applyDevelopSettings (settings, title)

    end


--[[----------------------------------------------------------------------------
private Point
pointToVisible (Point p, string orientation, number wv, number hv)

private Point
pointFromVisible (Point p, string orientation, number wv, number hv)

private number
angleToVisible (number a, string orientation)

private number
angleFromVisible (number a, string orientation)

Translates a point or angle from photo coordinates to visible coordinates
and vice versa.  "orientation" is the image's mirroring/rotation
orientation from getDevelopSettings(), and "wv" and "hv" are the width and
height of the image in visible coordinates.
------------------------------------------------------------------------------]]

    --[[ The CropLeft, CropRight, CropTop, CropBottom settings represent the
    crop applied to the original unrotated, unmirrored image. All of our
    computations, and what the user wants to see, should be relative to the
    coordinate system of the visible image. So we need to transform the
    stored settings into visible-image coordinates. ]]
local OrientationTransform = {
    ["AB"] = {rotate =    0, xDelta = 0, yDelta = 0, mirror = false},
    ["BC"] = {rotate =  -90, xDelta = 0, yDelta = 1, mirror = false},
    ["CD"] = {rotate = -180, xDelta = 1, yDelta = 1, mirror = false},
    ["DA"] = {rotate = -270, xDelta = 1, yDelta = 0, mirror = false},
    ["BA"] = {rotate =    0, xDelta = 0, yDelta = 0, mirror = true},
    ["CB"] = {rotate =  -90, xDelta = 0, yDelta = 1, mirror = true},
    ["DC"] = {rotate = -180, xDelta = 1, yDelta = 1, mirror = true},
    ["AD"] = {rotate = -270, xDelta = 1, yDelta = 0, mirror = true}}

function pointToVisible (p, orientation, wv, hv)
    local t = OrientationTransform [orientation] or 
        OrientationTransform ["AB"]
    p = pRot (p, {x = 0, y = 0}, t.rotate)
    p = pAdd (p, {x = t.xDelta * wv, y = t.yDelta * hv})
    if t.mirror then p.x = -p.x + wv end
    return p
    end

function pointFromVisible (p, orientation, wv, hv)
    local t = OrientationTransform [orientation] or 
        OrientationTransform ["AB"]
    if t.mirror then p.x = -p.x + wv end
    p = pSub (p, {x = t.xDelta * wv, y = t.yDelta * hv})
    p = pRot (p, {x = 0, y = 0}, -t.rotate)
    return p
    end

function angleToVisible (a, orientation)
    local t = OrientationTransform [orientation] or 
        OrientationTransform ["AB"]
    return t.mirror and -a or a
    end 

function angleFromVisible (a, orientation)
    local t = OrientationTransform [orientation] or 
        OrientationTransform ["AB"]
    return t.mirror and -a or a
    end 

--[[----------------------------------------------------------------------------
private Point
p (number x, number y)

Returns a point with the given coordinates.
------------------------------------------------------------------------------]]

function p (x, y)
    return {x = x, y = y}
    end

--[[----------------------------------------------------------------------------
private Point
pCen (Point p1, Point p2)

Returns the center of two points.
------------------------------------------------------------------------------]]

function pCen (p1, p2)
    return {x = (p1.x + p2.x) / 2, y = (p1.y + p2.y) / 2}
    end

--[[----------------------------------------------------------------------------
private Point
pRot (Point p, Point o, number a)

Rotates point p around the point o by angle a (positive = counterclockwise).
------------------------------------------------------------------------------]]

function pRot (p, o, a)
    local ar = rad (a)
    local x1, y2 = p.x - o.x, p.y - o.y
    local x2, y2 = x1 * cos (ar) - y2 * sin (ar), x1 * sin (ar) + y2 * cos (ar)
    return {x = x2 + o.x, y = y2 + o.y}
    end

--[[----------------------------------------------------------------------------
private Point
pAdd (Point p1, Point p2)

Returns p1 + p2
------------------------------------------------------------------------------]]

function pAdd (p1, p2)
    return {x = p1.x + p2.x, y = p1.y + p2.y}
    end

--[[----------------------------------------------------------------------------
private Point
pSub (Point p1, Point p2)

Returns p1 - p2
------------------------------------------------------------------------------]]

function pSub (p1, p2)
    return {x = p1.x - p2.x, y = p1.y - p2.y}
    end

--[[----------------------------------------------------------------------------
private Point
pMul (Point p, number n)

Returns p * n
------------------------------------------------------------------------------]]

function pMul (p, n)
    return {x = p.x * n, y = p.y * n}
    end

--[[----------------------------------------------------------------------------
private Point
pDist (Point p1, Point p2)

Returns the distance between points p1 and p2.
------------------------------------------------------------------------------]]

function pDist (p1, p2)
    return sqrt ((p1.x - p2.x) ^ 2 + (p1.y - p2.y) ^ 2)
    end
--[[----------------------------------------------------------------------------
------------------------------------------------------------------------------]]

return Crop
