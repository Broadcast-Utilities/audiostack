# AudioStack

## Broadcast Utilities

**AudioStack** is a modular audio streaming solution built on top of [Liquidsoap](https://www.liquidsoap.info) and [Icecast](https://icecast.org). It is designed to provide reliable, failover-capable broadcasting with minimal manual intervention.

---

## Components

1. **Liquidsoap**  
   Serves as the central audio router and transcoder. It handles source selection, failover logic, and stream processing.

2. **Icecast**  
   Acts as the public-facing distribution server, delivering audio streams to end users or relay targets over the internet.

---

## System Design

The architecture prioritizes uninterrupted streaming through a tiered source fallback system:

- **Primary Source**: `STUDIO_A`  
  Used as the main audio input when active and not silent.

- **Fallback 1**: `STUDIO_B`  
  Automatically selected when `STUDIO_A` is unavailable or silent.

- **Fallback 2**: *Emergency Track*  
  A predefined local audio file is played when both studio sources are unavailable or silent.

This structured failover mechanism ensures continuous audio delivery in all scenarios.

---

## Compatibility

- Tested on **Ubuntu 24.04**
- Supports **x86_64** architectures
- Requires an **active internet connection** for resolving external script dependencies

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE.md) file for details.