# Compatibility

## Cameras that support display of autofocus points

* Canon
  * Mirrorless: entire R-series
  * DSLR: all EOS models after 2004 (starting with EOS-1D Mark II)
  * Compact: Powershot models after 2004

 
* Nikon
  * Mirrorless: entire Z-series
  * DSLR: all D models with 39 or more autofocus points (from D3/D300 in 2007 to D6/D780 in 2020)
  * Compact: CoolPix models not supported

  
* Sony
  * Full-frame: α7, α9, α1 bodies beginning 2018 (with α7 III / α7R II) 
  * APS-C: α6100, α6300, α6400, α6500, α6600, α6700, ..
  * Compact: RX series, beginning 2015 (with RX10 II and RX100 IV)
  * Face detection
  

* Fuji
  * Mirroless: X-series (from X100 in 2011 up to X-H2S today), GFX-series
  * Compact: FinePix models after 2007  
  * Face and subject detection


* Olympus / OM System
  * DSLR: entire E-series
  * Mirrorless: entire E-M series, OM-1, OM-3, OM-5
  * Olympus: Face detection
  * OM System: Face and subject detection


* Panasonic
  * Mirrorless: entire LUMIX G and S series
  * Compact: FZ, TZ/ZS, LX series - models after 2008
  * Face detection
  

* Pentax 
  * DSLR: all models with 11 or more autofocus points (from *istD in 2003 to K-3 III Mono in 2023)
  * Face detection
  

* Ricoh
  * GR III, GR IIIx, GR IV including HDF versions
  * Face detection


* Apple
  * iPhone (starting from at least iPhone 5)
  * Face/pet detection frames (visualizing "Person & Pets" information from Apple's Photos App)


## Cameras that support straightening images

The straightening function relies on the presence of the 'RollAngle' tag in the metadata. Therefore, its application is currently limited to:

- Canon 
  - R5 (FW 1.5), R5m2
  - R6m2 (FW 1.4), R6m3
  - R7 (FW 1.3), R8 (FW 1.2), R10??
- Nikon (D5, D500 and later models)
- Fuji (XT-5 and later models)<sup>1</sup>
- Olympus/OM (EM-1/5/10 III and later models)
- Panasonic (Lumix G6 and later models)
- Pentax (K-7 and later models)<sup>2</sup>
- Ricoh (GR III and later models)<sup>2</sup>

<sup>1</sup> Fuji represents roll angle information within the range of -1° to +1° as `RollAngle=0`. <br>
<sup>2</sup> Pentax and Ricoh also record roll angle information for the specified models. However, when used to straighten photos, the results are typically not as precise as those provided by other brands.

Unfortunately, it seems that Sony does not record roll angle information in photo metadata. Even a deep analysis of a series of custom-made A7RV test images did not reveal any evidence of its presence.
