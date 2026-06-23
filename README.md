# youtube-content-study

Claude Code skill — study a YouTube video from its link. Extracts **title, description, channel/upload metadata, chapters, tags, full transcript/narration, and timestamped visual keyframes** into one context pack for comprehensive AI understanding (audio narration + visual scenes correlated by timestamp).

## Install

Copy into your Claude Code skills dir:

```bash
git clone https://github.com/trisetiohidayat/youtube-content-study.git ~/.claude/skills/youtube-content-study
```

## Requirements

- `yt-dlp`
- `ffmpeg`

## Usage

```bash
# text pack: metadata + description + transcript
scripts/extract.sh "<youtube-url>"

# visual pack: timestamped keyframes (default 24, here 10)
scripts/frames.sh "<youtube-url>" 10
```

Then have the AI Read the produced `.md` and the `frames/t_HH-MM-SS.png` images. Frame timestamps align 1:1 with the transcript and chapters.

See `SKILL.md` for the full workflow.
