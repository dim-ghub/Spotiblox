#!/usr/bin/env bash

CONFIG_FILE="$HOME/.spotiblox"
MAX_TITLE_LEN=300
MAX_ARTIST_LEN=300

# Determine if running interactively
IS_INTERACTIVE=false
[[ -t 0 ]] && IS_INTERACTIVE=true

# Get or read ROBLOSECURITY cookie
get_cookie() {
    if [[ -f "$CONFIG_FILE" ]]; then
        COOKIE=$(base64 --decode "$CONFIG_FILE")
    else
        if [[ "$IS_INTERACTIVE" == true ]]; then
            read -rsp "Enter your .ROBLOSECURITY cookie: " COOKIE
            echo
            echo -n "$COOKIE" | base64 > "$CONFIG_FILE"
            chmod 600 "$CONFIG_FILE"
            echo "Cookie saved to $CONFIG_FILE"
        else
            echo "Cookie file not found and not running interactively. Exiting."
            exit 1
        fi
    fi
}

truncate_str() {
    local str="$1"
    local max_len="$2"
    if [[ ${#str} -gt $max_len ]]; then
        echo "${str:0:$max_len}…"
    else
        echo "$str"
    fi
}

LAST_TRACK=""
LAST_STATUS=""
CLEARED_ONCE=false
LAST_POSITION=""

update_about_me() {
    python3 - <<END
import requests, os, re

COOKIE = "$COOKIE"
title = os.environ.get("TITLE_BASH", "")
artist = os.environ.get("ARTIST_BASH", "")
status = os.environ.get("STATUS_BASH", "")
position = os.environ.get("POSITION_BASH", "0")
duration = os.environ.get("DURATION_BASH", "0")

# Fetch bad words dynamically
BADWORDS_URL = "https://www.cs.cmu.edu/~biglou/resources/bad-words.txt"
try:
    resp = requests.get(BADWORDS_URL, timeout=5)
    resp.raise_for_status()
    BADWORDS = [line.strip() for line in resp.text.splitlines() if line.strip()]
except Exception:
    BADWORDS = []

def censor(text):
    for word in BADWORDS:
        regex = re.compile(rf"\\b{re.escape(word)}\\b", re.IGNORECASE)
        text = regex.sub(lambda m: "*"*len(m.group()), text)
    return text

def format_time(microseconds):
    try:
        seconds = int(float(microseconds)/1_000_000)
    except (ValueError, TypeError):
        seconds = 0
    m = seconds // 60
    s = seconds % 60
    return f"{m}:{s:02d}"

# Always show timestamp when paused, otherwise show 0:00
pos_str = format_time(position) if status.lower() == "paused" else "0:00"
dur_str = format_time(duration)

# Truncate
if len(title) > $MAX_TITLE_LEN:
    title = title[:$MAX_TITLE_LEN] + "…"
if len(artist) > $MAX_ARTIST_LEN:
    artist = artist[:$MAX_ARTIST_LEN] + "…"

# Apply profanity filter
title = censor(title)
artist = censor(artist)

session = requests.Session()
session.cookies[".ROBLOSECURITY"] = COOKIE

try:
    token_req = session.post("https://auth.roblox.com/v2/logout")
    csrf_token = token_req.headers.get("x-csrf-token")
except Exception:
    csrf_token = ""

headers = {
    "x-csrf-token": csrf_token or "",
    "Content-Type": "application/x-www-form-urlencoded",
    "Origin": "https://www.roblox.com",
    "Referer": "https://www.roblox.com/"
}

if title and artist:
    # Play/pause symbols: ⏸ when playing, ▶ when paused
    play_symbol = "⏸" if status.lower() == "playing" else "▶"
    symbols_line = f"⏮   {play_symbol}   ⏭"

    blurb = f"{title}\nby {artist}\n{symbols_line}\n{pos_str} / {dur_str}\n\nReal time Spotify information powered by SpotiBlox\nDeveloped by DiM"
else:
    blurb = ""

data = {"description": blurb}

try:
    resp = session.post("https://users.roblox.com/v1/description",
                        data=data, headers=headers)
    print(f"Updated About Me:\n{blurb}\n(Status {resp.status_code})")
except Exception as e:
    print("Failed to update About Me:", e)
END
}

get_cookie

while true; do
    SPOTIFY=$(playerctl -l 2>/dev/null | grep -i spotify)
    if [[ -n "$SPOTIFY" ]]; then
        TITLE=$(playerctl -p spotify metadata xesam:title 2>/dev/null)
        ARTIST=$(playerctl -p spotify metadata xesam:artist 2>/dev/null)
        STATUS=$(playerctl -p spotify status 2>/dev/null)
        POSITION=$(playerctl -p spotify metadata mpris:position 2>/dev/null)
        DURATION=$(playerctl -p spotify metadata mpris:length 2>/dev/null)

        TRACK_ID="$TITLE|$ARTIST|$STATUS"

        if [[ "$TRACK_ID" != "$LAST_TRACK" ]] || [[ "$STATUS" != "$LAST_STATUS" ]]; then
            export TITLE_BASH="$TITLE"
            export ARTIST_BASH="$ARTIST"
            export STATUS_BASH="$STATUS"
            export POSITION_BASH="$POSITION"
            export DURATION_BASH="$DURATION"
            update_about_me
            LAST_TRACK="$TRACK_ID"
            LAST_STATUS="$STATUS"
            LAST_POSITION="$POSITION"
            CLEARED_ONCE=true
        fi
        
        # Update timestamp every 10 seconds when playing, instantly when paused
        if [[ "$STATUS" == "playing" ]] && [[ "$POSITION" != "$LAST_POSITION" ]]; then
            export POSITION_BASH="$POSITION"
            export DURATION_BASH="$DURATION"
            update_about_me
            LAST_POSITION="$POSITION"
            sleep 10
        elif [[ "$STATUS" == "paused" ]] && [[ "$POSITION" != "$LAST_POSITION" ]]; then
            export POSITION_BASH="$POSITION"
            export DURATION_BASH="$DURATION"
            update_about_me
            LAST_POSITION="$POSITION"
        fi
    else
        if [[ "$CLEARED_ONCE" = false ]]; then
            unset TITLE_BASH
            unset ARTIST_BASH
            unset STATUS_BASH
            unset POSITION_BASH
            unset DURATION_BASH
            update_about_me
            CLEARED_ONCE=true
            echo "No Spotify detected, cleared About Me"
        fi
        LAST_TRACK=""
        LAST_STATUS=""
        LAST_POSITION=""
    fi
    
    sleep 1
done
