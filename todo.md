# PSEUDOCODE (Python)

1. INPUT = URL CHAINE YOUTUBE
2. Get all videos URL (YoutubeAPI / yt_dlp)
3. Get each video transcript (YoutubeAPI / youtube-transcript-api)
4. Clean each transcript (re.sub)
5. Combine transcripts (.md files / vectors)
6. Create AI agent with combined transcripts as knowledge
7. Generate public URL to access created agent