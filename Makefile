dev:
	docker-compose up

build:
	docker-compose build

test:
	docker-compose run --rm api npm test

lint:
	docker-compose run --rm api npm run lint

clean:
	docker-compose down -v --remove-orphans

docker-build:
	docker build -t medinovai-lis-api .

docker-run:
	docker run -p 8080:8080 medinovai-lis-api
