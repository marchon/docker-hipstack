#################################################################
## Make Docker HipStack
##
##  export BUILD_ORGANIZATION=hipstack
##  export BUILD_REPOSITORY=hipstack
##  export BUILD_VERSION=$(hipstack -V)
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
BUILD_VERSION				          ?=0.2.0
BUILD_BRANCH		              ?=$(shell git branch | sed -n '/\* /s///p')
CONTAINER_NAME			          ?=hipstack.dev
CONTAINER_HOSTNAME	          ?=hipstack.dev
CONTAINER_ADDRESS             ?=$(shell docker port hipstack.dev 80)
HOST_PWD                      ?=/opt/sources/Hipstack/hipstack

##
##
##
default:
	@make image
	@make run

##
##
##
install:
	@echo "Installing ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	@npm install

##
## --form-rm=true
##
image:
	@echo "Building ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	@sudo docker build --rm=true --quiet=true --tag=$(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest .

##
## docker port ${CONTAINER_NAME} 80
## @docker rm -f ${CONTAINER_NAME} || true
run:
	@echo "Running ${CONTAINER_NAME}. Mounting ${HOST_PWD} to /usr/local/src/hipstack as read-only."
	@echo "Checking and dumping previous runtime [$(shell docker rm -f ${CONTAINER_NAME} 2>/dev/null; true)]."
	@docker run -itd \
		--name=${CONTAINER_NAME} \
		--hostname=${CONTAINER_HOSTNAME} \
		--publish=80 \
		--env=NODE_ENV=develop \
		--env=PHP_ENV=develop \
		--volume=${HOST_PWD}/bin:/usr/local/src/hipstack/bin:rw \
		--volume=${HOST_PWD}/lib:/usr/local/src/hipstack/lib:rw \
		--volume=${HOST_PWD}/etc:/usr/local/src/hipstack/etc:rw \
		--volume=${HOST_PWD}/test:/usr/local/src/hipstack/test:rw \
		--volume=${HOST_PWD}/test/functional/fixtures:/var/www/test:rw \
		$(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest
	@docker logs ${CONTAINER_NAME}
	@echo "Container started. Use 'make check' to test."

##
## Not goint to work when called from within a Make container on CoreOS
##
check:
	@echo "Checking uptime."
	@curl --silent ${CONTAINER_ADDRESS}/test/status.php
	@curl --silent ${CONTAINER_ADDRESS}/test/status.php?type=apache
	@curl --silent ${CONTAINER_ADDRESS}/test/status.php?type=php
	@curl --silent ${CONTAINER_ADDRESS}/test/status.php?type=hhvm
	@curl --silent ${CONTAINER_ADDRESS}/test/status.php?type=pagespeed

##
##
##
release:
	@echo "Releasing ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}:${BUILD_VERSION}."
	@make image
	@sudo docker tag $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
	@sudo docker push $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
	@sudo docker push $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):latest
	@sudo docker rmi $(BUILD_ORGANIZATION)/$(BUILD_REPOSITORY):$(BUILD_VERSION)
	@make remove

##
##
##
remove:
	@echo "Stopping development instances ${BUILD_ORGANIZATION}/${BUILD_REPOSITORY}."
	@docker stop ${CONTAINER_NAME} 2>/dev/null; true
	@docker rm -f ${CONTAINER_NAME} 2>/dev/null; true
