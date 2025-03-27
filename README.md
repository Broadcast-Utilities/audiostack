# AudioStack
## Broadcast Utilities
This repository contains an audio streaming solution. Using [Liquidsoap](https://www.liquidsoap.info) and [Icecast](https://icecast.org/).

## Components
1. **Liquidsoap**: Acts as the primary audio router and transcoder.
2. **Icecast**: Functions as a public server for distributing the audio stream.

## System design
The system design involves delivering the broadcast through SRT. Liquidsoap uses the main input (SRT 1) as much as possible. If it becomes unavailable or silent, the system switches to an emergency track.

## Compatibility
1. Tested on Ubuntu 24.04.
2. Supports x86_64 system architectures.
3. Requires an internet connection for script dependencies.
