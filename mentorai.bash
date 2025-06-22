#!/bin/bash

OUTPUT_DIR="./output"
PROMPT_TEMPLATE="./prompt_template.txt"

CHANNEL_ID=""
CHANNEL_ID_SAFE=""
CHANNEL_NAME=""
CHANNEL_DESCRIPTION=""
CHANNEL_URL=""
CHANNEL_VIDEOS_URL=""

VIDEO_IDS=""
VIDEO_COUNT=0
SUBTITLES_COUNT=0

main() {
    parse_args "$@"     || return 1
    fetch_channel       || return 2
    fetch_videos        || return 4
    download_subtitles  || return 5
    convert_subtitles   || return 6
    merge_transcripts         || return 7
    create_prompt       || return 8
    create_settings
}

parse_args() {
    if [[ "$1" =~ ^@[^/]+$ ]]; then
        CHANNEL_ID=$1
    elif [[ "$1" =~ ^[^/@][^/]*$ ]]; then
        CHANNEL_ID="@${1}"
    elif [[ "$1" =~ ^https://www\.youtube\.com/(@[^/]+)(/.*)?$ ]]; then
        CHANNEL_ID="${BASH_REMATCH[1]}"
    else
        echo "Usage: $0 <YouTube channel URL or ID>"
        return 1
    fi
}

fetch_channel() {
    # Check channel
    CHANNEL_URL="https://www.youtube.com/${CHANNEL_ID}"
    curl --silent --head --fail "${CHANNEL_URL}" > /dev/null || {
        echo "❌ INCORRECT CHANNEL: ${CHANNEL_URL}"
        return 1
    }

    CHANNEL_ID_SAFE="${CHANNEL_ID#@}"
    CHANNEL_VIDEOS_URL="${CHANNEL_URL}/videos"

    # Get metadata
    local json=$(yt-dlp --skip-download --dump-single-json --ignore-no-formats-error --playlist-items 0 "$CHANNEL_URL")
    if [[ -z "$json" || "$json" == "null" ]]; then
        echo "❌ Failed to retrieve channel metadata"
        return 1
    fi

    CHANNEL_NAME=$(echo "$json" | jq -r '.uploader')
    CHANNEL_DESCRIPTION=$(echo "$json" | jq -r '.description')
    echo "✅ CHANNEL FETCH => ${CHANNEL_NAME} - ${CHANNEL_DESCRIPTION}"

    mkdir -p "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}"

    local pp_url=$(echo "$json" | jq -r '.thumbnails | max_by(.width) | .url')
    if [[ -n "$pp_url" && "$pp_url" != "null" ]]; then
        curl -s -o "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/avatar.jpg" "$pp_url"
        echo "✅ Profile picture saved"
    else
        echo "⚠️  No profile picture found"
    fi

}

fetch_videos() {
    echo
    echo "Fetching videos ids..."

    VIDEO_IDS=$(yt-dlp -s --flat-playlist -i --print "%(id)s" "${CHANNEL_VIDEOS_URL}")
    VIDEO_COUNT=$(echo "$VIDEO_IDS" | wc -l | xargs)

    if (( $VIDEO_COUNT > 0 )); then
        echo "✅ $VIDEO_COUNT videos found"
    else
        echo "❌ No video found"
        return 1
    fi
}

download_subtitles() {
    echo
    echo "Downloading subtitles..."

    mkdir -p "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp"
    (
        cd "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp"
        local video_number=1
        for id in $VIDEO_IDS; do
            video_url="https://www.youtube.com/watch?v=${id}"
            yt-dlp --write-subs --write-auto-subs --sub-lang "fr" --sub-format "srt" --skip-download "${video_url}" > /dev/null 2>&1
            if compgen -G "*${id}*.srt" > /dev/null; then
                echo "✅ [$video_number/$VIDEO_COUNT] ${id} => Subtitles downloaded"
            else
                echo "⚠️  [$video_number/$VIDEO_COUNT] ${id} => No subtitles found"
            fi
            ((video_number++))
        done
    )

    SUBTITLES_COUNT=$(find "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp" -type f -name "*.srt" | wc -l | xargs)
    if (( $SUBTITLES_COUNT > 0 )); then
        echo "✅ $SUBTITLES_COUNT subtitles downloaded"
    else
        echo "❌ No subtitles found"
        return 1
    fi
}

convert_subtitles() {
    echo
    echo "Converting subtitles into transcripts..."

    find "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp" -type f -name "*.srt" | while IFS= read -r file; do
        file_name="${file%.srt}"
        grep -vE '^[0-9]+$|-->|^$' "$file" > "${file_name}.txt"
        rm -f "$file"
    done

    echo "✅ Transcripts created"
}

merge_transcripts() {
    echo
    echo "Merging files..."

    local merge_factor=$((SUBTITLES_COUNT / 20 + 1))
    local output_count=1
    local tmp_count=1

    for file in "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp"/*.txt; do
        [[ -f "$file" ]] || continue
        local filename=$(basename "$file")

        if (( tmp_count > merge_factor )); then
            (( output_count++ ))
            tmp_count=1
        fi

        local output_file="${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/transcript-${output_count}.txt"

        local id=$(echo "$filename" | sed -E 's/^.*\[(.{11})\]\.fr\.txt$/\1/')
        local name=$(echo "$filename" | sed -E 's/ \[[^]]+\]\.fr\.txt$//')

        {
            echo "---------"
            echo "VIDEO_URL=https://www.youtube.com/watch?v=${id}"
            echo "VIDEO_NAME=${name}"
            echo ""
            cat "$file"
            echo ""
            echo "---------"
            echo ""
        } >> "$output_file"

        ((tmp_count++))
    done

    rm -rf "${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/tmp"

    echo "✅ Files merged"
}

create_prompt() {
    echo
    echo "Creating prompt..."
    
    local output="${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/prompt.txt"

    if [[ ! -f "$PROMPT_TEMPLATE" ]]; then
        echo "❌ Unable to find prompt template : $PROMPT_TEMPLATE"
        return 1
    fi

    sed \
        -e "s|\[CHANNEL_NAME\]|$CHANNEL_NAME|g" \
        -e "s|\[CHANNEL_ID\]|$CHANNEL_ID|g" \
        -e "s|\[CHANNEL_DESCRIPTION\]|$CHANNEL_DESCRIPTION|g" \
        "$PROMPT_TEMPLATE" > "$output"

    echo "✅ Prompt created"
}

create_settings() {
    local output_file="${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/settings.txt"
    {
        echo "Go to:        https://chatgpt.com/gpts/editor"
        echo "Picture:      ${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/avatar.jpg"
        echo "Name:         ${CHANNEL_NAME}"
        echo "Description:  ${CHANNEL_DESCRIPTION}"
        echo "Pre-prompt:   ${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/prompt.txt"
        echo "Trigger 1:    Par où commencer ?"
        echo "Trigger 2:    Quelles vidéos regarder ?"
        echo "Trigger 3:    J'ai besoin d'un conseil"
        echo "Knowledge:    ${OUTPUT_DIR}/${CHANNEL_ID_SAFE}/transcript-*.txt"
    } >> "${output_file}"

    echo
    cat "${output_file}"
    echo
}

main "$@"
