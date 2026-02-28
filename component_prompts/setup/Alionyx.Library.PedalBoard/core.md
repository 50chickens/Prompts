# Flexible Multi-Device Audio Routing Architecture

## Overview

Alsionyx supports flexible, low-latency audio routing through a **pedalboard-centric architecture** where audio flows from input devices, through the pedalboard's plugin chain, to output devices. The pedalboard acts as the central routing hub - inputs and outputs are NOT directly connected unless explicitly configured by the user.

## Audio Flow Architecture

### Pedalboard as Central Hub

### Key Principles

1. **No Direct Connection**: Input devices do NOT directly connect to output devices
2. **Pedalboard Processing**: All audio passes through the pedalboard's plugin chain
3. **User-Controlled Routing**: User explicitly defines:
   - Which input devices/channels feed into the pedalboard
   - How plugins are connected within the pedalboard
   - Which output devices/channels receive the processed audio
4. **Flexible Connections**: User can optionally create direct input→output connections within the pedalboard if desired

## Key Capabilities

### 1. Multi-Backend Input/Output

Users can select different backends for input and output independently:

- **Input Backends**: FileAudio, SoundFlow (real devices), Mock
- **Output Backends**: FileAudio, SoundFlow (real devices), Mock
- **Mix and Match**: Combine FileAudio input with multiple real device outputs

### 2. Multi-Device Selection

Within each backend (especially SoundFlow), select multiple devices:

- Select multiple input devices simultaneously
- Route to multiple output devices in parallel
- Each device can have different channel counts

### 3. Per-Channel Routing Through Pedalboard

Route individual audio channels through the pedalboard to specific destinations:

### Channel Selection

```csharp
// Select specific channels from device
var channelMapper = new ChannelMapper();
channelMapper.MapInput(deviceId: "device1", channel: 0, to: "virtual:input:0");
channelMapper.MapOutput(from: "virtual:output:0", deviceId: "device2", channels: [2, 3]);

### 1. Zero-Copy Optimization

Where possible, avoid copying audio buffers:
- Direct device-to-device routing
- Shared memory buffers
- Reference passing instead of value copying

### 2. Buffer Management

Efficient buffer strategies:
- Ring buffers for smooth streaming
- Pre-allocated buffer pools
- Lock-free circular queues

### 3. Thread Synchronization

Minimize lock contention:
- One audio thread per device
- Lock-free message passing for coordination
- SPSC queues for inter-thread communication

### 4. Sample Rate Conversion

Handle different device sample rates:
- High-quality resampling (SoundFlow built-in)
- Configurable quality vs latency trade-off
- Automatic rate detection and conversion
