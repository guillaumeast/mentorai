# 🧠 `mentorai` v0.1.0

Minimal YouTube-to-GPT generator – converts any YouTube channel into a ready-to-upload Custom GPT package, **in one CLI command**.

[![Language: Bash](https://img.shields.io/badge/language-Bash-blue)](https://www.gnu.org/software/bash/)
[![Platform: macOS/Linux](https://img.shields.io/badge/platform-macOS%20%26%20Linux-darkgreen)](https://en.wikipedia.org/wiki/Unix-like)
[![Status: v0.1.0](https://img.shields.io/badge/status-v0.1.0-yellow)](https://github.com/guillaumeast/mentorai/releases)

> **`mentorai`** creates a complete Custom GPT pack from any YouTube channel, including profile, prompt, and transcript knowledge –  
> so you can talk to your favorite creator, expert, or guru… as if they were right there with you.

---

## ✨ Features

- Fully local – no API keys or cloud services needed
- Only requires [`yt-dlp`](https://github.com/yt-dlp/yt-dlp)
- Supports full channel URLs or YouTube handles (e.g. `@CoachGali`)
- Outputs everything needed to configure a GPT via [chat.openai.com/gpts](https://chat.openai.com/gpts):
  - 🖼️ Profile picture
  - 🧠 Cleaned and chunked transcripts (20 files max)
  - 🪄 Pre-prompt and GPT settings (name, description, instructions)
- Friendly file structure in `output/<channel_id_safe>/`

---

### 🚀 Usage

```bash
./mentorai.bash https://www.youtube.com/@GoogleDevelopers
```

or just:

```bash
./mentorai.bash @GoogleDevelopers
```

Output will be created in:

```bash
output/GoogleDevelopers/
├── avatar.jpg
├── settings.txt
├── prompt.txt
├── transcript-1.txt
├── ...
└── transcript-20.txt
```

---

### 📦 Dependencies

- `yt-dlp` – fetches videos, metadata and subtitles  
- `jq` – parses JSON output from `yt-dlp`  
- `curl` – checks URLs and downloads channel avatar  
- `grep` – cleans subtitle `.srt` files  
- `sed` – template variable replacement & filename parsing  
- `bash`, `wc`, `xargs` – core shell utilities (standard on macOS/Linux)

Install example (macOS) :
```bash
brew install yt-dlp jq curl grep gnu-sed
```

---

## 🧪 Example

```bash
./mentorai.sh https://www.youtube.com/@CoachGali
```

Then go to [https://chat.openai.com/gpts](https://chat.openai.com/gpts) and:
1. Upload `avatar.jpg`
2. Copy-paste settings from `settings.txt`
3. Upload `transcript-*.txt` files
4. Done.

---

## 🧱 Project structure

```
mentorai/
├── README.md
├── mentorai.bash
├── prompt_template.txt
└── output/
    └── <channel_id_safe>/
        ├── avatar.png
        ├── settings/
        └── knowledge/
```

---

## 👤 Author

Made with 🧠 by [@guillaumeast](https://github.com/guillaumeast)
