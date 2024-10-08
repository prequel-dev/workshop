SHELL := /bin/bash

ECR_PUBLIC := public.ecr.aws/prequel-dev

DOCKER_IMAGE := workshop/messages-generator

.PHONY: all
all: release

release: build_generator

BINDIR := ./bin

.PHONY: build
build_generator: 
	mkdir -p $(BINDIR)
	docker buildx build \
		--target=binary \
		--output ./bin/ \
		--ssh=default \
		.

# Build the image
.PHONY: image
image: 
	docker buildx build \
		-t $(DOCKER_IMAGE) \
		--target generator-image \
		--platform linux/amd64 \
		--ssh=default \
		-f Dockerfile .

deploy_release: SERVER=$(ECR_PUBLIC)
deploy_release: TAG=latest
deploy_release: aws deploy

.PHONY: aws
aws:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(ECR_PUBLIC)

.PHONY: deploy
deploy: image
	docker tag $(DOCKER_IMAGE):latest $(ECR_PUBLIC)/$(DOCKER_IMAGE):latest
	docker push $(ECR_PUBLIC)/$(DOCKER_IMAGE):latest

# Clean up the generated build artifacts
.PHONY: clean
clean:
	rm -rf $(BINDIR)


