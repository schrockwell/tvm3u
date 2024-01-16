# 📺 TVM3U

## Un-time-shift your content.

This little Sinatra app:

1. Serves up "channel" playlists whose time within the playlist is persisted, so when you return to the channel, it's like it kept playing in the background. Like TV used to be.

2. Has webhooks to control a local instance of the VLC player to "change the channel".

There is a "sleep timer" that automatically puases playback 2 hours after the latest command was given.

## Endpoints

HTTP port: 1337

- Playlists
  - `/channel/current.m3u` - fetch current channel
  - `/channel/next.m3u` - go to and fetch the next channel
  - `/channel/prev.m3u` - go to and fetch the previous channel
- VLC Control
  - `/go/next` - go to the next channel
  - `/go/prev` - go to the previous channel
  - `/go/play` - play theh current channel
  - `/go/pause` - pause the current channel

## Requirements

- VLC running with the HTTP control on port 8080 with password `tvm3u`.
- Playlists in the `m3u` folder (see the README there for details).
