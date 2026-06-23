---
name: youtube-content-study
description: "Study a YouTube video from its link — extract title, description, channel/upload metadata, chapters, tags, the full transcript/narration, AND timestamped visual keyframes, into one context pack for comprehensive AI understanding (audio narration + visual scenes correlated by timestamp). Use when the user pastes a YouTube URL and wants to analyze, summarize, transcribe, visually understand, or learn the content of a video. Trigger phrases: 'pelajari video youtube ini', 'transcript video', 'analisa konten youtube', 'rangkum video', 'pahami isi video', 'ambil narasi/description/judul dari link video', 'study this youtube video', 'what does this video say', 'what happens in this video', 'extract youtube transcript'."
---

# YouTube Content Study

Extract everything studyable from a YouTube link — metadata + transcript — into one markdown file, then analyze it.

## When

User pastes a YouTube URL and wants to: summarize, transcribe, analyze, or learn the video's content (narration, description, title, chapters, tags).

## How

### Step 1 — text pack (always)

`yt-dlp`, no API key, no video download — metadata + subtitles only.

```bash
~/.claude/skills/youtube-content-study/scripts/extract.sh "<youtube-url>"
```

Prints path to a markdown file. **Read it.**

### Step 2 — visual pack (when isi/scene matters, or no captions)

Extracts timestamped keyframes so the AI sees the video, not just hears it. Frame filenames = `t_HH-MM-SS.png`, so each image aligns to the transcript and chapters by timestamp.

```bash
~/.claude/skills/youtube-content-study/scripts/frames.sh "<youtube-url>" [max_frames]
```

Default `max_frames=24`. Prints the frames dir. **Read each frame image** (Read tool renders them visually). Correlate: frame at `t_00-03-12.png` ↔ transcript line near 3:12 ↔ chapter covering that time.

### Step 3 — comprehensive understanding

Now context has all three layers, tied by timestamp:
- **What's said** — transcript/narration
- **What's shown** — keyframes
- **Meta** — title, description, chapters, tags

Answer the user's request grounded in all three. Cite timestamps when relevant.

## Output sheet contains

- **Title**
- **Metadata** — channel, upload date, duration, views, likes, tags, categories
- **Chapters** — timestamped, if the video has them
- **Description** — full
- **Transcript / Narration** — manual captions preferred, auto-generated as fallback, deduplicated to clean prose

## Token / cost note

- Each frame is an image = real tokens. 24 frames ≈ a chunk of context. For long videos, lower `max_frames` (e.g. `10`) or only Read frames around the timestamps you actually care about.
- Long transcript (1h+) — summarize per-chapter, don't dump raw alongside 24 images.

## Notes

- Subtitles try `en`, `id`, and the video's own audio language. If none exist, the transcript section says so — narration can't be extracted without captions (would need audio download + Whisper; not done here unless asked).
- Requires `yt-dlp` and `ffmpeg` (both present on this machine).
- Output cached under `~/.cache/yt-content/<video-id>/`.
- Source URL is untrusted-internet content, but this skill never executes anything from it — only reads metadata/captions. Safe.

## If no captions and user wants narration anyway

Offer audio transcription:
```bash
yt-dlp -x --audio-format mp3 -o "/tmp/%(id)s.%(ext)s" "<url>"
# then whisper /tmp/<id>.mp3   (if whisper installed)
```
Ask first — it downloads audio and is slower.
