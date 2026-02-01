# Docker Build and Run Guide

This document provides instructions for building and running Alsionyx in Docker containers.

## Building the Docker Image

### Build the API image
```bash
docker build -t alsionyx-api:latest .
```

### Build and run tests
```bash
docker build --target test -t alsionyx-api-test:latest .
docker run --rm alsionyx-api-test:latest
```

## Running with Docker

### Run the API container
```bash
docker run -d \
  --name alsionyx-api \
  -p 5000:5000 \
  -e ASPNETCORE_ENVIRONMENT=Development \
  alsionyx-api:latest
```

### Run with docker-compose
```bash
# Run the API service
docker-compose up -d alsionyx-api

# Run tests
docker-compose run --rm alsionyx-api-test

# View logs
docker-compose logs -f alsionyx-api

# Stop services
docker-compose down
```

## Testing the API

Once the container is running, you can test the API endpoints:

```bash
# Check audio status
curl http://localhost:5000/audio/status

# Get available backends
curl http://localhost:5000/api/audio/backends

# Get backend details
curl http://localhost:5000/api/audio/backends/Mock

# Get backend status
curl http://localhost:5000/api/audio/backends/Mock/status

# Get backend metrics
curl http://localhost:5000/api/audio/backends/Mock/metrics

# Get backend controls
curl http://localhost:5000/api/audio/backends/Mock/controls

# Get control value
curl http://localhost:5000/api/audio/backends/Mock/controls/master_volume

# Set control value
curl -X PUT http://localhost:5000/api/audio/backends/Mock/controls/master_volume \
  -H "Content-Type: application/json" \
  -d "50"

# Load a plugin
curl -X POST http://localhost:5000/api/audio/backends/Mock/plugins \
  -H "Content-Type: application/json" \
  -d '{"pluginUri": "http://example.org/plugins/reverb"}'

# Get loaded plugins
curl http://localhost:5000/api/audio/backends/Mock/plugins

# Get connections
curl http://localhost:5000/api/audio/backends/Mock/connections

# Create a connection
curl -X POST http://localhost:5000/api/audio/backends/Mock/connections \
  -H "Content-Type: application/json" \
  -d '{"fromPort": "instance_1:output_1", "toPort": "system:playback_1"}'
```

## Development Workflow

### Build and test in one command
```bash
docker build --target test -t alsionyx-test . && \
docker run --rm alsionyx-test
```

### Interactive debugging
```bash
# Build and run with bash shell
docker run -it --rm \
  --entrypoint /bin/bash \
  alsionyx-api:latest
```

## CI/CD Integration

The Dockerfile is designed to work with CI/CD pipelines:

1. **Build stage**: Compiles the solution
2. **Test stage**: Runs all unit and integration tests
3. **Publish stage**: Creates the deployment artifacts
4. **Runtime stage**: Minimal runtime image for production

Build checks run on every commit and will fail if:
- Code doesn't compile
- Tests fail
- Dependencies can't be restored

## Troubleshooting

### Build fails with restore errors
```bash
# Clear Docker build cache
docker builder prune

# Rebuild without cache
docker build --no-cache -t alsionyx-api:latest .
```

### Container exits immediately
```bash
# Check logs
docker logs alsionyx-api

# Run interactively to see errors
docker run -it --rm alsionyx-api:latest
```

### Port already in use
```bash
# Use a different port
docker run -d -p 5001:5000 alsionyx-api:latest
```

## Multi-Stage Build Details

The Dockerfile uses a multi-stage build:

1. **build**: Restores dependencies and builds the solution
2. **test**: Runs all tests (can be targeted separately)
3. **publish**: Publishes the API for deployment
4. **runtime**: Final minimal image with only runtime dependencies

This approach:
- Keeps the final image small
- Allows testing before deployment
- Separates build and runtime dependencies
- Improves build caching
