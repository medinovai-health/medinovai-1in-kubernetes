# Makefile for medinovai-real-time-stream-bus

# Default target
dev:
	docker-compose up

# Build the Docker image
build:
	docker-compose build

# Run tests
test:
	docker-compose run --rm app npm test

# Lint the code
lint:
	docker-compose run --rm app npm run lint

# Clean up
clean:
	docker-compose down

# Build the Docker image for production
docker-build:
	docker build -t medinovai-real-time-stream-bus:latest .

# Run the Docker container
docker-run:
	docker run -p 3000:3000 medinovai-real-time-stream-bus:latest
