ELRChatBot.Core. has core libraries. 
ELRChatBot.Library.ChatGPT. service/libary to communicating with chatgpt. 
ELRChatBot.Library.DataExtraction. for the re-implemented .dox & .pdf data extraction c# code. 
ELRChatBot.Api - controller endpoints/DI wiring only. 
    has swagger. 
    requires a /info endpoint to verify the api is functional. this /info endpoint should just return 200 OK.  the /info endpoint is a normal .net service and needs to be DI wired just like the chatgpt libraries. 
    

ELRChatBot.ConsoleApp.ListModels. 

ELRChatBot.ConsoleApp.HelloWorld. consume ELRChatBot.Library.ChatGPT directly to get model list directly from chatgpt. also calls chatgpt api directly to get "hello world" response. this tests the chatgpt, and the api key before starting the docker container. 
ELRChatBot.Api.Client.HelloWorld. once the docker-container is started:
    Call the API /info endpoint to verify the api in the docker container is up. 
    once it gets 200 OK back from the /info it should call the api to get hello world response from chatgpt. 