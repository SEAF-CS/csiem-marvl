# Assemble the 22-Aug-1991 flood-tide PYCNOCLINE clip (images/hq_1991_flood/f_###.png) into MP4 (+GIF).
# Run AFTER render_hq_1991_flood.R finishes (or to preview however many frames exist).
# 37 hourly frames; play slow (5 fps -> ~7.4 s) so the smooth flood + pulse reads. Tune FPS to taste.
import glob, os, imageio.v2 as imageio

FRAMES = sorted(glob.glob("images/hq_1991_flood/f_*.png"))
FPS    = 5
MP4    = "images/pycnocline_flood_22aug1991.mp4"
GIF    = "images/pycnocline_flood_22aug1991.gif"

if not FRAMES:
    raise SystemExit("no frames in images/hq_1991_flood/")
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
