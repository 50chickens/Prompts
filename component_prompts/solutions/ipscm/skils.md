# ipscm Generic Infrastructure Implementation Plan

## Project and Class Summary

ipscm provides cross-cutting infrastructure shared across all solutions: 
logging abstraction, 
dependency injection container setup with Autofac module for wiring services,
HTTP infrastructure for mod-ui protocol parameter endpoints.
No domain-specific code belongs here; only reusable infrastructure for config, DI, logging, and HTTP handling.

## Implementation Notes

Logging uses a factory pattern allowing multiple underlying implementations. Autofac container setup centralizes DI configuration registering logging, HTTP services, audio library components, and plugins services. HTTP utilities provide a lightweight server and handler abstraction compatible with mod-ui protocol for parameter updates over HTTP, supporting both float control parameters and string-type properties that plugins may expose. All infrastructure types accept constructor dependencies with no static service locators. Configuration is externalized allowing different setups for console app vs library usage. The Autofac module in ipscm is referenced by the console application for dependency wiring.


logging:

C:\git\internal\Ipscm\src\Ipscm.Library or ~/git/internal/Ipscm/src/Ipscm.Library contains a logging library using nlog. don't reimplement any yourself. this is available in a nuget package.