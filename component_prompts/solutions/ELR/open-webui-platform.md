this document has a list of changes to the way the open-webui software is hosted. 

Customizations:
We need to enable & configure the open-terminal feature in open-webui by default. the open-webui documentation allows for us to add an additional service to the docker-compose file: 

services:
  open-webui:
    #open-webui docker-compose configuration here.
  open-terminal:
    image: ghcr.io/open-webui/open-terminal
    container_name: open-terminal
    volumes:
      - open-terminal:/home/user
    environment:
      - OPEN_TERMINAL_API_KEY=your-secret-key

Enable the open-terminal feature by calling the open-webui api and configuring it in the invoke-deployment script. 