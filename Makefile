REGISTRY ?= registry.gitlab.com/tbsweiss/opendesk-sogo-image
TAG ?= bookworm-5.12.9

build:
	docker build -t $(REGISTRY):$(TAG) -t $(REGISTRY):latest .

push:
	docker push $(REGISTRY):$(TAG)
	docker push $(REGISTRY):latest

.PHONY: build push
