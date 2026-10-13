# obs-multistream

Stream to **X (Twitter)**, **YouTube**, and **Twitch** at the same time from a
single OBS Studio instance — one "Start Streaming" click goes live everywhere.

| File | Purpose |
| :--- | :--- |
| `obs/service.json` | OBS's primary stream output → X (pscp.tv) |
| `obs/obs-multi-rtmp.json` | obs-multi-rtmp plugin targets → YouTube + Twitch, `sync-start`/`sync-stop` bound to the primary output |
| `obs/basic.ini`, `obs/streamEncoder.json` | Profile + encoder settings (1080p canvas → 720p30, CBR 4000k, VAAPI) |
| `bin/xstream-guard` | Watchdog that recovers from X's single-publisher lock |
| `bin/xstream-recover` | Manual "it's thrashing, fix it" reset |
| `configure.sh` | Writes a real profile with your keys into `~/.config/obs-studio` |

## Requirements

- OBS Studio (developed on OBS 30/31, Linux; the configs are portable)
- [obs-multi-rtmp](https://github.com/sorayuki/obs-multi-rtmp) plugin,
  installed under `~/.config/obs-studio/plugins/`
- A stream key for each platform

## Setup

1. Close OBS (`pkill -x obs`) — it rewrites profile files on exit.
2. Run `./configure.sh`. It prompts for your three stream keys and writes a
   profile to `~/.config/obs-studio/basic/profiles/<name>/`.
   **Keys never touch this repo.**
   Non-interactive: set `X_STREAM_KEY`, `YOUTUBE_STREAM_KEY`,
   `TWITCH_STREAM_KEY` (plus optional `PROFILE_NAME`, `VIDEO_DIR`,
   `TWITCH_INGEST`) before running.
3. Open OBS → Profile → select it → Settings → Stream should show
   service **Twitter** with your X key.
4. The obs-multi-rtmp dock lists the YouTube and Twitch targets.
   Click **Start Streaming** once — all three outputs go live together
   (`sync-start`), and stop together (`sync-stop`).

## The X publisher-lock problem (why the guard exists)

pscp.tv allows exactly **one** publisher per stream key. After any
disconnect, X holds a lock for ~60–240 s. obs-multi-rtmp retries every ~2 s,
so a single failed attempt becomes an infinite thrash: every retry is
EPIPE-killed and resets the lock timer.

`xstream-guard` tails the newest OBS log. When `Reconnecting in` appears
≥3 times within the last 40 lines — a thrash signature, not a recovered
blip — it kills OBS, waits out the lock (default 300 s), and relaunches.
Counting only the recent tail matters: a long stream can legitimately log
several isolated reconnects that already recovered, and a cumulative count
would eventually kill a healthy stream.

```bash
xstream-guard &     # background watchdog; exits when OBS exits
xstream-recover     # manual full reset: kill → wait → relaunch → re-arm guard
```

Tunables (env): `LOCK_WAIT_SECS`, `RECONNECT_MAX`, `RECONNECT_WINDOW`,
`POLL_SECS`, `OBS_LOGDIR`, `DISPLAY`, `XAUTHORITY`.

> After a guard-initiated relaunch, click **Start** on the X target once —
> obs-multi-rtmp v0.7.x has no autostart/websocket hook to do it for you.

## Notes / gotchas

- `basic.ini` ships `Reconnect=false` + `MaxRetries=0` **on purpose**: OBS's
  own auto-reconnect triggers the same pscp thrash. Leave it off — the
  guard is the recovery path.
- The encoder preset is VAAPI (`ffmpeg_vaapi_tex`, AMD/Linux, CBR 4000 kbps).
  For NVIDIA/Intel/software, switch `Encoder` in Settings → Output
  (`NVENC`/`QSV`/`x264`) and adjust `streamEncoder.json` to match.
- `configure.sh` defaults the Twitch ingest to `rtmp://live.twitch.tv/app`,
  which auto-selects the nearest endpoint. Pin a region with
  `TWITCH_INGEST=rtmp://live-<region>.twitch.tv/app`.
- X ingest is `rtmp://va.pscp.tv:80/x` — plain RTMP on port 80 is what
  pscp.tv expects.
- Keep OBS closed while editing profile files; it rewrites them on exit.

## License

MIT
