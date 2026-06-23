#!/usr/bin/env bash
# Extract timestamped keyframes from a YouTube video for visual understanding.
# Frames are named by their timestamp so they align with the transcript/chapters.
#
# Usage:
#   frames.sh <url> [N]              interval mode: N frames spread evenly (default 24)
#   frames.sh <url> scene [thresh]   scene mode: a frame on every visual change
#                                    thresh 0..1, lower = more sensitive (default 0.3)
#
# interval mode = cheap, predictable, but BLIND to changes between samples.
# scene mode   = catches every cut/UI change regardless of timing; frame count
#                depends on the video (a slideshow-heavy screencast yields many).
set -euo pipefail

URL="${1:?usage: frames.sh <url> [N | scene [thresh]]}"
MODE="${2:-24}"
OUTDIR="${4:-$HOME/.cache/yt-content}"

ID="$(yt-dlp --no-warnings --print id "$URL" | head -1)"
DUR="$(yt-dlp --no-warnings --print duration "$URL" | head -1)"
WORK="$OUTDIR/$ID"
FR="$WORK/frames"
mkdir -p "$FR"
rm -f "$FR"/t_*.png "$FR"/seq_*.png "$FR"/scene_*.png "$FR"/info.log

# Low-res download (≤480p) — enough for visual understanding, small + fast.
VID="$WORK/$ID.video.mp4"
if [ ! -f "$VID" ]; then
  yt-dlp --no-warnings -f "bv*[height<=480]+ba/b[height<=480]/best" \
    --merge-output-format mp4 \
    -o "$WORK/$ID.video.%(ext)s" "$URL" >/dev/null
  [ -f "$VID" ] || VID="$(ls "$WORK/$ID.video".* 2>/dev/null | head -1)"
fi

label_secs() { # float seconds -> t_HH-MM-SS.png path
  python3 -c "t=int(float('$1'));print(f'$FR/t_%02d-%02d-%02d.png'%(t//3600,(t%3600)//60,t%60))"
}

if [ "$MODE" = "scene" ]; then
  THRESH="${3:-0.3}"
  # select frames where scene-change score > THRESH. showinfo prints pts_time
  # to stderr in emission order; we map each output PNG to its real timestamp.
  ffmpeg -loglevel info -y -i "$VID" \
    -vf "select='gt(scene,$THRESH)',showinfo,scale=640:-1" \
    -vsync vfr "$FR/scene_%05d.png" 2> "$FR/info.log"

  TIMES=()
  while IFS= read -r line; do TIMES+=("$line"); done < <(grep -oE 'pts_time:[0-9.]+' "$FR/info.log" | cut -d: -f2)
  i=0
  for f in "$FR"/scene_*.png; do
    [ -e "$f" ] || break
    t="${TIMES[$i]:-$i}"
    mv "$f" "$(label_secs "$t")"
    i=$((i+1))
  done
else
  N="$MODE"
  INTERVAL="$(python3 -c "import math;print(max(5, math.floor($DUR/max(1,$N))))")"
  FPS="$(python3 -c "print(1/$INTERVAL)")"
  ffmpeg -loglevel error -y -i "$VID" -vf "fps=$FPS,scale=640:-1" "$FR/seq_%05d.png"
  i=0
  for f in "$FR"/seq_*.png; do
    [ -e "$f" ] || break
    mv "$f" "$(label_secs "$(python3 -c "print($i*$INTERVAL)")")"
    i=$((i+1))
  done
fi

rm -f "$VID" "$FR/info.log"
echo "$FR"
echo "frames: $(ls "$FR"/t_*.png 2>/dev/null | wc -l | tr -d ' ')"
