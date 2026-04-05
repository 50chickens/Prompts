# Phase Basic — Architecture Plan

## Overview

Build an OpenAI-compatible API that wraps the official OpenAI SDK and runs locally on Windows. The API will implement sufficient endpoints for open-webui to connect and test basic chat completions with ChatGPT.

## SDK Choice

Uses official OpenAI SDK from C:\git\external\openai-dotnet. Generated from OpenAI's official spec, maintains official best practices, includes DI support, and actively maintained.

## Components

Core layer defines service abstraction for chat completions. Infrastructure layer wraps the official OpenAI SDK. API layer exposes OpenAI-compatible endpoints.

## Projects (4 total)

ELRChatBot.Core provides interfaces and domain models. ELRChatBot.Api is the ASP.NET Core web service hosting the OpenAI spec endpoints. ELRChatBot.ConsoleApp.ListModels queries the API to verify available models. ELRChatBot.ConsoleApp.HelloWorld tests chat completion with a default prompt or user-supplied prompt via command line.

## Endpoints

POST /v1/chat/completions handles chat requests with optional streaming. GET /v1/status returns API health. GET /v1/models lists available models.

## Service Architecture

Interface in Core defines chat completion contract. Implementation in Infrastructure instantiates the OpenAI client, manages API key from environment variable, and transforms responses to OpenAI spec format. Dependency injection wires services at startup using default application builder pattern.

## Error Handling

Friendly error messages returned to caller via OpenAI spec error format. Exceptions logged to file. Configuration specifies log file path and location.

## Orchestration Pipeline

ci.ps1 invokes build-test.ps1 which compiles solution and runs integration tests. invoke-deployment.ps1 creates docker-compose manifest including both open-webui and ELRChatBotApi services, then runs console apps as integration tests to verify the API endpoint responds correctly to hello world request.

Ensure the `data\` folder structure is always ready before the containers start. Do not delete/erase/wipe or remove files from this folder for any reason ever.. 
## Deployment

Static docker-compose.yml committed to repo. API runs on localhost:5000 via HTTP. open-webui configured to connect to local API endpoint. All functionality testable on Windows only.

## Configuration

API key read from OPENAI_API_KEY environment variable. Model name, temperature, max tokens configured via JSON config file. Log output path configurable. 

1. Swagger/OpenAPI Generation
Should the API auto-generate OpenAPI spec from code, or manually maintain it to match OpenAI spec exactly?
Use the basic chat streaming pattern from the examples to build a mvp. 

2. Model List Endpoint
Should GET /v1/models hardcode available models, or query OpenAI to get the full list?
get the full list. this is what the ListModels console app should already do.

3. Request Validation
Should we validate incoming requests strictly (all required fields present), or be lenient and use defaults?
Don't set defaults unless mandatory. dont make the implementation too brittle.

4. Console Apps Testing
Should the console apps be invoked by invoke-deployment.ps1 or run separately as manual tests?
it should have the following workflow: 
run the ListModels. this should query the Models from chatgpt directly and not through the api.
it should run the docker-compose container containing the open-webui and the api and then the ELRChatBot.ConsoleApp.HelloWorld should call the api in the container to verify that we can use it to connect to chatgpt. 