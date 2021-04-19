up: docker-up
down: docker-down
restart: docker-down docker-up
init: docker-down-clear manager-clear docker-pull docker-build docker-up manager-init
test: manager-test
test-coverage: manager-test-coverage
test-unit: manager-test-unit
test-unit-coverage: manager-test-unit-coverage

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull

docker-build:
	docker-compose build

manager-init: manager-composer-install manager-ready

manager-clear:
	docker run --rm -v ./manager:/app --workdir=/app alpine rm -f .ready

manager-composer-install:
	docker-compose run --rm manager-php-cli composer install

manager-ready:
	docker run --rm -v ./manager:/app --workdir=/app alpine touch .ready

manager-test:
	docker-compose run --rm manager-php-cli php bin/phpunit

manager-test-coverage:
	docker-compose run --rm manager-php-cli php bin/phpunit --coverage-clover var/clover.xml --coverage-html var/coverage

manager-test-unit:
	docker-compose run --rm manager-php-cli php bin/phpunit --testsuite=unit

manager-test-unit-coverage:
	docker-compose run --rm manager-php-cli php bin/phpunit --testsuite=unit --coverage-clover var/clover.xml --coverage-html var/coverage

build-production:
	docker build --pull --file=manager/docker/production/nginx.docker --tag ${REGISTRY_ADDRESS}/manager-nginx:${IMAGE_TAG} manager
	docker build --pull --file=manager/docker/production/php-fpm.docker --tag ${REGISTRY_ADDRESS}/manager-php-fpm:${IMAGE_TAG} manager
	docker build --pull --file=manager/docker/production/php-cli.docker --tag ${REGISTRY_ADDRESS}/manager-php-cli:${IMAGE_TAG} manager
	docker build --pull --file=manager/docker/production/postgres.docker --tag ${REGISTRY_ADDRESS}/manager-postgres:${IMAGE_TAG} manager

push-production:
	docker push ${REGISTRY_ADDRESS}/manager-nginx:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/manager-php-fpm:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/manager-php-cli:${IMAGE_TAG}
	docker push ${REGISTRY_ADDRESS}/manager-postgres:${IMAGE_TAG}
deploy-production:
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'rm -rf docker-compose.yml .env'
	scp -o StrictHostKeyChecking=no -P ${PRODUCTION_PORT} docker-compose-production.yml ${PRODUCTION_HOST}:docker-compose.yml
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "REGISTRY_ADDRESS=${REGISTRY_ADDRESS}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'echo "IMAGE_TAG=${IMAGE_TAG}" >> .env'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'docker-compose pull'
	ssh -o StrictHostKeyChecking=no ${PRODUCTION_HOST} -p ${PRODUCTION_PORT} 'docker-compose --build -d'