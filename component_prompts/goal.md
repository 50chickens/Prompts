# LV2 Plugin Console Application

Build a lightweight Linux console application that can discover, load, and manage LV2 audio plugins. The application provides a plugin discovery service, audio routing through a connection matrix, and a command-line interface for plugin management with mod-ui support for parameter modification.

## Core Requirements

The application must discover all installed LV2 plugins on the system by scanning standard LV2 plugin directories. It creates named pedalboards which are collections of plugins with audio routing between them. Each pedalboard manages its own connection matrix allowing arbitrary port-to-port connections between plugin instances. The user can add and remove plugin instances to any pedalboard, connect audio between them, and modify plugin parameters either through the CLI or through mod-ui protocol for web-based control.

## Architecture

The solution is divided into layered libraries with a console application entry point. Alsionyx.Library.Audio provides core abstractions for audio devices and connection matrices. Alsionyx.Library.Audio.Lv2 handles LV2 plugin loading and discovery using lilv library bindings. Alsionyx.Library.PedalBoard manages pedalboard state and plugin lifecycle. The console app ties these together exposing a command-line interface for pedalboard and plugin operations, with mod-ui HTTP interface support for parameter updates.

## Component Plans

setup/Alsionyx.Library.Audio - [plan.md](solutions/setup/Alsionyx.Library.Audio/plan.md)
Establishes IAudioDevice and IConnectionMatrix abstractions, SoundFlowAudioDevice for system audio I/O via the SoundFlow library, ChannelMapper for port routing, and PortConnection and PluginParameter supporting types.

setup/Alsionyx.Library.Audio.Lv2 - [plan.md](solutions/setup/Alsionyx.Library.Audio.Lv2/plan.md)
Implements generic LV2 plugin discovery scanning ~/.lv2 and system plugin directories. Provides ILv2PluginLoader and ILv2PluginInstance for loading and operating any LV2 plugin. Wraps lilv for descriptor reading. Supports both float control ports and string-type properties that plugins may expose.

setup/Alsionyx.Library.PedalBoard - [plan.md](solutions/setup/Alsionyx.Library.PedalBoard/plan.md)
Manages pedalboard collections, plugin instance lifecycle, parameter storage, and persistence. IPedalboardService exposes full CRUD and parameter operations including SetStringPropertyAsync for plugins with string-based parameters.

ipscm - [plan.md](solutions/ipscm/plan.md)
Provides shared logging abstraction, Autofac DI module for wiring all services, and HTTP infrastructure compatible with mod-ui protocol for parameter updates over HTTP.

alsionyx/Alsionyx.Services.Plugins - [plan.md](solutions/alsionyx/Alsionyx.Services.Plugins/plan.md)
Service layer for plugin discovery and pedalboard command operations. IPluginDiscoveryService wraps ILv2PluginLoader. IPedalboardCommandService coordinates pedalboard and plugin lifecycle. Coordinates with SoundFlow audio routing to establish audio paths through loaded plugins.

## Definition of Done

The console application uses the Autofac DI container with the ipscm Autofac module registered at startup.

The console app uses IPluginDiscoveryService to discover installed LV2 plugins. The loader is fully generic and handles any LV2 plugin. Plugins are looked up by URI and their available parameters are read from the discovered metadata.

For any discovered plugin that exposes string-type properties, the console app can set those properties via SetStringPropertyAsync on IPedalboardCommandService.

The console app uses the SoundFlow library via SoundFlowAudioDevice to take audio from the primary input device, route it through a loaded plugin instance in a pedalboard, and send the output to the primary output device.
