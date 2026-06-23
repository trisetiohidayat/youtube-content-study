#!/usr/bin/env python3
"""Turn yt-dlp info.json + optional .vtt into one clean markdown study sheet.
Usage: format.py <info.json> [subtitles.vtt]
ponytail: stdlib only (json/re/sys). No webvtt lib — vtt cue stripping is ~15 lines.
"""
import json
import re
import sys
from datetime import datetime


def fmt_date(s):
    if not s or len(s) != 8:
        return s or "?"
    try:
        return datetime.strptime(s, "%Y%m%d").strftime("%Y-%m-%d")
    except ValueError:
        return s


def fmt_dur(sec):
    if not sec:
        return "?"
    sec = int(sec)
    h, m, s = sec // 3600, (sec % 3600) // 60, sec % 60
    return f"{h}:{m:02d}:{s:02d}" if h else f"{m}:{s:02d}"


def parse_vtt(path):
    """Collapse a VTT into deduplicated plain transcript text."""
    with open(path, encoding="utf-8", errors="replace") as f:
        raw = f.read()
    lines = []
    for ln in raw.splitlines():
        ln = ln.strip()
        if not ln or ln == "WEBVTT":
            continue
        if "-->" in ln or ln.isdigit():
            continue
        if ln.startswith(("NOTE", "Kind:", "Language:")):
            continue
        # strip inline timestamp tags <00:00:00.000> and <c> styling
        ln = re.sub(r"<[^>]+>", "", ln)
        ln = ln.strip()
        if ln:
            lines.append(ln)
    # dedupe consecutive repeats (auto-subs roll the same line repeatedly)
    out = []
    for ln in lines:
        if not out or out[-1] != ln:
            out.append(ln)
    return " ".join(out)


def main():
    info_path = sys.argv[1]
    vtt_path = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] else None

    with open(info_path, encoding="utf-8") as f:
        d = json.load(f)

    title = d.get("title", "?")
    print(f"# {title}\n")
    print("## Metadata\n")
    print(f"- **URL**: {d.get('webpage_url', '?')}")
    print(f"- **Channel**: {d.get('uploader', '?')} ({d.get('channel_url', '?')})")
    print(f"- **Uploaded**: {fmt_date(d.get('upload_date'))}")
    print(f"- **Duration**: {fmt_dur(d.get('duration'))}")
    print(f"- **Views**: {d.get('view_count', '?')}  |  **Likes**: {d.get('like_count', '?')}")
    if d.get("tags"):
        print(f"- **Tags**: {', '.join(d['tags'][:25])}")
    if d.get("categories"):
        print(f"- **Categories**: {', '.join(d['categories'])}")
    print()

    if d.get("chapters"):
        print("## Chapters\n")
        for c in d["chapters"]:
            print(f"- `{fmt_dur(c.get('start_time'))}` {c.get('title', '')}")
        print()

    print("## Description\n")
    print(d.get("description", "").strip() or "_(none)_")
    print()

    print("## Transcript / Narration\n")
    if vtt_path:
        txt = parse_vtt(vtt_path)
        print(txt if txt else "_(subtitle file empty)_")
    else:
        print("_(no subtitles available — manual or auto-generated captions not found)_")
    print()


if __name__ == "__main__":
    main()
