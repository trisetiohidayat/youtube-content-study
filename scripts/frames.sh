#!/usr/bin/env bash
# Extract timestamped keyframes from a YouTube video for visual understanding.
# Frames are named by their timestamp so they align with the transcript/chapters.
# Usage: frames.sh <youtube-url> [max_frames] [outdir]
# ponytail: fixed-interval sampling (not scene-detect) so timestamps stay exact
#           and align 1:1 with transcript. Upgrade to scene-detect only if a
#           user needs cut-accurate keyframes.
set -euo pipefail

URL="${1:?usage: frames.sh <youtube-url> [max_frames] [outdir]}"
MAXF="${2:-24}"
OUTDIR="${3:-$HOME/.cache/yt-content}"

ID="$(yt-dlp --no-warnings --print id "$URL" | head -1)"
DUR="$(yt-dlp --no-warnings --print duration "$URL" | head -1)"
WORK="$OUTDIR/$ID"
FR="$WORK/frames"
mkdir -p "$FR"

# Sample interval: spread MAXF frames across the whole video, floor 5s.
INTERVAL="$(python3 -c "import math,sys;d=float(sys.argv[1]);n=int(sys.argv[2]);print(max(5, math.floor(d/max(1,n))))" "$DUR" "$MAXF")"
FPS="$(python3 -c "print(1/$INTERVAL)")"

# Low-res download (≤480p) — enough for scene/visual understanding, small + fast.
VID="$WORK/$ID.video.mp4"
if [ ! -f "$VID" ]; then
  yt-dlp --no-warnings -f "bv*[height<=480]+ba/b[height<=480]/best" \
    --merge-output-format mp4 \
    -o "$WORK/$ID.video.%(ext)s" "$URL" >/dev/null
  # merger may still settle on a non-mp4 container; grab whatever it produced
  [ -f "$VID" ] || VID="$(ls "$WORK/$ID.video".* 2>/dev/null | head -1)"
fi

# Extract frames at fixed fps, scale to 640px wide, label PNG by timestamp.
# Two-pass: ffmpeg emits sequential frames; we rename to real seconds.
TMP="$FR/seq_%05d.png"
ffmpeg -loglevel error -y -i "$VID" -vf "fps=$FPS,scale=640:-1" "$TMP"

i=0
for f in "$FR"/seq_*.png; do
  [ -e "$f" ] || break
  t=$(python3 -c "print(int($i*$INTERVAL))")
  h=$((t/3600)); m=$(((t%3600)/60)); s=$((t%60))
  label=$(printf "%02d-%02d-%02d" "$h" "$m" "$s")
  mv "$f" "$FR/t_${label}.png"
  i=$((i+1))
done

# ponytail: keep the lowres video? No — delete, frames are the artifact. Re-derive cheap.
rm -f "$VID"

echo "$FR"
ls "$FR"/t_*.png 2>/dev/null | wc -l | tr -d ' ' | xargs -I{} echo "frames: {}"
