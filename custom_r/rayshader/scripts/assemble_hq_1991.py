# Assemble the 1991 storm PYCNOCLINE orbit HQ frames (images/hq_1991/f_###.png) into MP4 (+GIF).
# Run AFTER render_hq_1991_orbit.R finishes (or to preview however many frames exist).
# FPS is a free post-step (no re-render): 61 frames @ 8 fps -> ~7.6 s. Tune FPS to taste.
import glob, os, imageio.v2 as imageio

FRAMES = sorted(glob.glob("images/hq_1991/f_*.png"))
FPS    = 8
MP4    = "images/pycnocline_hq_1991_storm_orbit.mp4"
GIF    = "images/pycnocline_hq_1991_storm_orbit.gif"

if not FRAMES:
    raise SystemExit("no frames in images/hq_1991/")
print(f"{len(FRAMES)} frames -> {MP4} @ {FPS} fps")

try:
    with imageio.get_writer(MP4, fps=FPS, codec="libx264", quality=8,
                            macro_block_size=8) as w:
        for f in FRAMES:
            w.append_data(imageio.imread(f))
    print("wrote", MP4, f"({os.path.getsize(MP4)/1e6:.1f} MB)")
except Exception as e:
    print("MP4 failed:", e)

# GIF fallback / shareable
imageio.mimsave(GIF, [imageio.imread(f) for f in FRAMES], duration=1.0/FPS)
print("wrote", GIF, f"({os.path.getsize(GIF)/1e6:.1f} MB)")
