.PHONY: ubuntu-x86_64 ubuntu-arm64v8 build qemu-wrap build push clean

ERLANG_VER := 21.0.3
ELIXIR_VER :=  1.6.6
QEMU_STATIC_VERSION := 2.12.0

ubuntu-x86_64: BASE_IMAGE := ubuntu:bionic
ubuntu-x86_64: DISTRO := ubuntu
ubuntu-x86_64: TAG := ubuntu-x86_64
ubuntu-x86_64: build push

ubuntu-arm64v8: BASE_IMAGE := arm64v8/ubuntu:bionic
ubuntu-arm64v8: DISTRO := ubuntu
ubuntu-arm64v8: TAG := ubuntu-arm64v8
ubuntu-arm64v8: QEMU_ARCH := aarch64
ubuntu-arm64v8: qemu-wrap build push

qemu-%-static.tar.gz:
	curl -LO https://github.com/multiarch/qemu-user-static/releases/download/v$(QEMU_STATIC_VERSION)/$@

qemu-%-static: qemu-%-static.tar.gz
	tar xzf $?

qemu-wrap: DOCKER_FILE := $(shell mktemp)
qemu-wrap:
	$(MAKE) qemu-$(QEMU_ARCH)-static
	sed 's!%%BASE_IMAGE%%!$(BASE_IMAGE)!g' qemu-wrapper/Dockerfile.tmpl > $(DOCKER_FILE)
	docker build --pull --build-arg QEMU_ARCH=$(QEMU_ARCH) -t $(BASE_IMAGE) -f $(DOCKER_FILE) .
	rm -f qemu-$(QEMU_ARCH)-static

build: DOCKER_FILE := $(shell mktemp)
build:
	sed 's!%%BASE_IMAGE%%!$(BASE_IMAGE)!g' Dockerfile.$(DISTRO).tmpl > $(DOCKER_FILE)
	docker build \
		--build-arg ERLANG_VER=$(ERLANG_VER) \
		--build-arg ELIXIR_VER=$(ELIXIR_VER) \
		-t graffic/elixir:$(TAG) \
		-f $(DOCKER_FILE) .
	
push:
	docker push graffic/elixir:$(TAG)
clean:
	rm -f qemu-*-static qemu-*-static.tar.gz