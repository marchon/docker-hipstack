#################################################################
## Make Docker HipStack
##
##  export BUILD_ORGANIZATION=hipstack
##  export BUILD_REPOSITORY=hipstack
##  export BUILD_VERSION=0.1.5
##
##  docker build -t ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:latest .
##
##  docker run \
##    --rm \
##    --volume=$(pwd):/data$( pwd) \
##    --workdir=/data$(pwd) \
##    --env=NODE_ENV=development \
##    --env=GIT_BRANCH=$(git branch | sed -n '/\* /s///p') \
##    node npm install
##
#################################################################

BUILD_ORGANIZATION	          ?=hipstack
BUILD_REPOSITORY		          ?=hipstack
BUILD_VERSION				          ?=0.1.5
BUILD_BRANCH		              ?=$(shell git branch | sed -n '/\* /s///p')
CONTAINER_NAME			          ?=hipstack
CONTAINER_HOSTNAME	          ?=hipstack.internal

default: dockerImage

install:
	@echo "Installing ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	@npm install

dockerImage:
	@echo "Building ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	@docker build -t $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest .

restart:
	@docker restart ${CONTAINER_NAME}

stop:
	@docker stop ${CONTAINER_NAME}

start:
	@docker rm -f ${CONTAINER_NAME}
	run

tests:
	@echo "Testing HipStack <${BUILD_BRANCH}> branch."
	@mocha test/unit
	@mocha test/functional
	@mocha test/integration

run:
	@echo "Running ${CONTAINER_NAME}."
	@echo "Checking and dumping previous runtime. $(shell docker rm -f ${CONTAINER_NAME} 2>/dev/null; true)"
	@sudo docker run -itd \
		--name=${CONTAINER_NAME} \
		--hostname=${CONTAINER_HOSTNAME} \
		--env=NODE_ENV=${NODE_ENV} \
		--env=PHP_ENV=${PHP_ENV} \
		$(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest
	@docker logs ${CONTAINER_NAME}

dockerRelease:
	@echo "Releasing ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	docker tag $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
	docker push $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
	@docker rmi $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
