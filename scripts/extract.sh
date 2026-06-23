#!/usr/bin/env bash
# Extract YouTube content (metadata + transcript) to a single markdown file.
# Usage: extract.sh <youtube-url> [outdir]
# ponytail: yt-dlp does all heavy lifting; this just orchestrates + formats.
set -euo pipefail

URL="${1:?usage: extract.sh <youtube-url> [outdir]}"
OUTDIR="${2:-$HOME/.cache/yt-content}"
mkdir -p "$OUTDIR"

ID="$(yt-dlp --no-warnings --print id "$URL" | head -1)"
WORK="$OUTDIR/$ID"
mkdir -p "$WORK"

# 1. Metadata JSON (title, description, uploader, dates, tags, chapters, etc.)
yt-dlp --no-warnings --skip-download --write-info-json \
  -o "$WORK/%(id)s.%(ext)s" "$URL" >/dev/null

# 2. Subtitles: prefer manual, fall back to auto. Try common langs.
yt-dlp --no-warnings --skip-download \
  --write-subs --write-auto-subs \
  --sub-langs "en.*,id.*,$(yt-dlp --no-warnings --print language "$URL" 2>/dev/null | head -1)" \
  --sub-format vtt \
  -o "$WORK/%(id)s.%(ext)s" "$URL" >/dev/null 2>&1 || true

INFO="$WORK/$ID.info.json"
OUT="$WORK/$ID.md"

# Pick first vtt subtitle file if any.
VTT="$(ls "$WORK"/*.vtt 2>/dev/null | head -1 || true)"

python3 "$(dirname "$0")/format.py" "$INFO" "$VTT" > "$OUT"
echo "$OUT"
