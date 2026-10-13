#!/usr/bin/env bash
# configure.sh — write a real OBS multistream profile from the templates
# in obs/, prompting for your stream keys.
#
# Keys are written ONLY into your local OBS profile directory:
#   $OBS_DIR/basic/profiles/$PROFILE_NAME/
# Nothing is written back into this repo — never commit real keys.
#
# Env overrides (non-interactive):
#   X_STREAM_KEY YOUTUBE_STREAM_KEY TWITCH_STREAM_KEY
#   PROFILE_NAME (default MultiStream)
#   VIDEO_DIR    (default ~/Videos)
#   TWITCH_INGEST (default rtmp://live.twitch.tv/app — auto nearest ingest)
#   OBS_DIR      (default ~/.config/obs-studio)
#   FORCE=1      overwrite an existing profile dir without asking

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OBS_DIR="${OBS_DIR:-$HOME/.config/obs-studio}"
PROFILE_NAME="${PROFILE_NAME:-MultiStream}"
VIDEO_DIR="${VIDEO_DIR:-$HOME/Videos}"
TWITCH_INGEST="${TWITCH_INGEST:-rtmp://live.twitch.tv/app}"

prompt_secret() {  # VARNAME "prompt"
  local varname="$1" prompt="$2" val="${!1:-}"
  if [ -z "$val" ]; then
    read -r -s -p "$prompt: " val; echo >&2
  fi
  [ -n "$val" ] || { echo "error: $varname is required" >&2; exit 1; }
  printf -v "$varname" '%s' "$val"
}

prompt_secret X_STREAM_KEY       "X/Twitter stream key (pscp.tv / Media Studio)"
prompt_secret YOUTUBE_STREAM_KEY "YouTube stream key"
prompt_secret TWITCH_STREAM_KEY  "Twitch stream key"

DEST="$OBS_DIR/basic/profiles/$PROFILE_NAME"
if [ -d "$DEST" ] && [ "${FORCE:-0}" != "1" ]; then
  read -r -p "$DEST exists — overwrite? [y/N] " ans
  case "$ans" in [yY]*) ;; *) echo "aborted"; exit 1;; esac
fi
mkdir -p "$DEST"

fill() {
  sed -e "s|__X_STREAM_KEY__|${X_STREAM_KEY}|g" \
      -e "s|__YOUTUBE_STREAM_KEY__|${YOUTUBE_STREAM_KEY}|g" \
      -e "s|__TWITCH_STREAM_KEY__|${TWITCH_STREAM_KEY}|g" \
      -e "s|__TWITCH_INGEST__|${TWITCH_INGEST}|g" \
      -e "s|__PROFILE_NAME__|${PROFILE_NAME}|g" \
      -e "s|__VIDEO_DIR__|${VIDEO_DIR}|g" \
      "$1" > "$2"
}

fill "$HERE/obs/service.json"        "$DEST/service.json"
fill "$HERE/obs/obs-multi-rtmp.json" "$DEST/obs-multi-rtmp.json"
fill "$HERE/obs/basic.ini"           "$DEST/basic.ini"
cp   "$HERE/obs/streamEncoder.json"  "$DEST/streamEncoder.json"

echo "wrote profile '$PROFILE_NAME' to $DEST"
echo "open OBS → Profile → $PROFILE_NAME, then check Settings → Stream"
