dev:
	docker-compose up

build:
	docker-compose build

test:
	docker-compose run --rm app npm test

lint:
	docker-compose run --rm app npm run lint

clean:
	docker-compose down -v --remove-orphans

docker-build:
	docker build -t medinovai-canary-rollout-orchestrator .

docker-run:
	docker run -p 8080:8080 medinovai-canary-rollout-orchestrator
