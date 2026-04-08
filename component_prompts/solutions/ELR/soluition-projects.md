ELRChatBot.Core. has core libraries. 
ELRChatBot.Library.ChatGPT. service/libary to communicating with chatgpt. 
ELRChatBot.Library.DataExtraction. for the re-implemented .docx/doc & .pdf data extraction c# code. 
ELRChatBot.Library.OpenWebUi.Tooling. contains unit testable code that can be called via a the open-webui tool-calling feature. references ELRChatBot.Library.DataExtraction & ELRChatBot.Library.ChatGPT. is intended to be called from python.net.
ELRChatBot.Api.ChatGPT - controller endpoints/DI wiring only. 
    has swagger. 
    requires a /info endpoint to verify the api is functional. this /info endpoint should just return 200 OK.  the /info endpoint is a normal .net service and needs to be DI wired just like the chatgpt libraries. 

ELRChatBot.ConsoleApp.ListModels. 

ELRChatBot.ConsoleApp.HelloWorld. consume ELRChatBot.Library.ChatGPT directly to get model list directly from chatgpt. also calls chatgpt api directly to get "hello world" response. this tests the chatgpt, and the api key before starting the docker container. 
ELRChatBot.Api.ChatGPT.Client.HelloWorld. once the docker-container is started:
    Call the API /info endpoint to verify the api in the docker container is up. 
    once it gets 200 OK back from the /info it should call the api to get hello world response from chatgpt. 


ELRChatBot constraints.

* Core layer defines service abstraction for chat completions. Infrastructure layer wraps the official OpenAI SDK. API layer exposes OpenAI-compatible endpoints.
* Interface in Core defines chat completion contract. Implementation in Infrastructure instantiates the OpenAI client, manages API key from environment variable, and transforms responses to OpenAI spec format. Dependency injection wires services at startup using default application builder pattern.
* Friendly error messages returned to caller via OpenAI spec error format. Exceptions logged to file. Configuration specifies log file path and location.

ELRChatBot.Api.ChatGPT constraints.

* POST /v1/chat/completions handles chat requests with optional streaming. GET /v1/status returns API health. GET /v1/models lists available models.
* The API will implement sufficient endpoints for open-webui to connect and test basic chat completions with ChatGPT.
* Implement GET /v1/models to list all models from openapi api. 

Uses ELRChatBot.Library.ChatGPT.

ELRChatBot.Library.ChatGPT constraints.
* Implemnts an OpenAI-compatible API that wraps the official OpenAI SDK and runs locally on Windows. 
* Uses official OpenAI SDK from C:\git\external\openai-dotnet. Generated from OpenAI's official spec.
* API key read from OPENAI_API_KEY environment variable. Model name, temperature, max tokens configured via JSON config file. Log output path configurable. 