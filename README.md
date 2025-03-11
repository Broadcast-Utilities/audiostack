# Broadcast Utilities AudioStack
This repository contains an audio streaming solution made for [Breeze Radio](https://breezeradio.nl)  Using [Liquidsoap](https://www.liquidsoap.info) and [Icecast](https://icecast.org/).

## Components
1. **Liquidsoap**: Acts as the primary audio router and transcoder.
2. **Icecast**: Functions as a public server for distributing the audio stream.

## System design
The system design involves delivering the broadcast through SRT. Liquidsoap uses the main input (SRT 1) as much as possible. If it becomes unavailable or silent, the system switches to an emergency track.

## Scripts
- **icecast2.sh**: This script installs Icecast 2 and provides SSL support via Let's Encrypt/Certbot. Execute it using `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/broadcast-utilities/audiostack/main/icecast2.sh)"`
- **install.sh**: Installs Liquidsoap with fdkaac support in a Docker container. Execute it using `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/broadcast-utilities/audiostack/main/install.sh)"`
- **monitor.sh**: Experimental log parser for Liquidsoap status. Not installed by default. Work in progress. (⚠️ BROKEN - Needs rewrite to work with Docker logs)

## Configurations
- **radio.liq**: A production-ready Liquidsoap configuration that incorporates StereoTool as a MicroMPX encoder.
- **docker-compose.yml**: Basic Liquidsoap configuration in Docker.

## Compatibility
1. Tested on Ubuntu 24.04 and Debian 12.
2. Supports x86_64 or ARM64 system architectures (e.g., Ampere Altra, Raspberry Pi). Note: StereoTool MicroMPX is currently not well-supported on ARM architectures.
3. Requires an internet connection for script dependencies.
