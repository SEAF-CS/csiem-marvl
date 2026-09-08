# Assemble the HQ path-traced frames (images/hq_frames/f_###.png) into MP4 (+GIF).
# Run AFTER render_series_hq.R finishes (or to preview however many frames exist).
import glob, os, imageio.v2 as imageio

FRAMES = sorted(glob.glob("images/hq_frames/f_*.png"))
FPS    = 12
MP4    = "images/oxycline_hq_20240113_23.mp4"
GIF    = "images/oxycline_hq_20240113_23.gif"

if not FRAMES:
    raise SystemExit("no frames in images/hq_frames/")
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
