# HQ path-tracing with render_highquality (rayrender)

`render_highquality()` re-renders the scene as a **CPU Monte-Carlo path trace** (rayrender, uses
RcppThread — NOT the GPU; a better GPU does nothing). Cinematic GI/soft shadows, but inherently noisy
and slow (~300 s+/frame). The rasteriser (`render_snapshot`) is noise-free and ~6 s/frame — use it for
previews and when GI isn't needed.

## Getting custom geometry into the path trace (the big gotcha)
render_highquality only keeps rgl meshes whose **tag** `convert_rgl_to_raymesh()` recognises. An overlay
added via `rgl::shade3d(..., tag="iface")` is **silently dropped** → terrain-only output. Fix: build the
overlay as a **rayrender object** and pass via `scene_elements=`. scene_elements are added AFTER the
terrain is shifted by `-bbox_center`, so shift your object by the same vector. Replicate it on the
terrain-only scene:
```r
rhq_bbox_center <- function() {
  rotmat <- rayshader:::rot_to_euler(rgl::par3d()$userMatrix)
  phi <- rotmat[1]; if (90-abs(phi) < 0.001) phi <- -phi
  um <- rgl::par3d()$userMatrix[,4]
  if (0.001 > abs(abs(rotmat[3])-180))
    mv <- rgl::rotationMatrix(-rotmat[2]*pi/180,0,1,0) %*% rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  else mv <- rgl::rotationMatrix(rotmat[3]*pi/180,0,0,1) %*% rgl::rotationMatrix(rotmat[2]*pi/180,0,1,0) %*%
             rgl::rotationMatrix(-phi*pi/180,1,0,0) %*% um
  bb <- rgl::par3d()$bbox
  c(mean(bb[1:2]),mean(bb[3:4]),mean(bb[5:6])) - mv[1:3]
}
bc  <- rhq_bbox_center()
oxy <- rayrender::mesh3d_model(tmesh3d_of_surface, x=-bc[1], y=-bc[2], z=-bc[3],
                               override_material=TRUE, material=rayrender::diffuse(color="#d7301f"))
render_highquality(out, scene_elements=oxy, clear=FALSE, ...)
```
A faint **water surface** at 0 m AHD = a thin blue dielectric `rayrender::cube` slab, also shifted by -bc.
(working template: `scripts/hq_water_frame.R`.)

## Noise control (forwarded via `...` to `rayrender::render_scene`)
- `integrator_type="nee"` (next-event estimation) — **the big win**; directly samples lights each bounce,
  far less shadow noise than the default `"rtiow"`. ~3× slower/sample but worth it.
- `denoise=TRUE` is the default (OIDN). `clamp_value=8` kills fireflies.
- Noise is worst in DARK regions → a **bright multi-light wrap** raises SNR. Locked oxycline config:
  `lightdirection=c(315,135,45,225)`, `lightaltitude=c(50,45,40,55)`, `lightintensity=c(480,300,280,260)`.
- `sample_method="sobol_blue"` caps at **256 samples** (auto-falls back to `sobol` above) — lock 256.
- ~17 min/frame at NEE/256/1100×950 → ~18-20 h for 66 frames. `render_series_hq.R` is **resumable**
  (skips frames whose PNG exists) and builds the terrain once (`clear=FALSE`, swaps scene_elements/camera).
