.PHONY: ubuntu-x86_64 \
		alpine-x86_64 \
		normal-build \
		ubuntu-arm64v8 \
		alpine-arm64v8 \
		wrapped-build \
		build-all build qemu-wrap build push register clean

ERLANG_VER := 21.0.3
ELIXIR_VER :=  1.6.6
QEMU_STATIC_VERSION := 2.12.0

build-all: register alpine-arm64v8 ubuntu-arm64v8 alpine-x86_64 ubuntu-x86_64

ubuntu-x86_64: BASE_IMAGE := ubuntu:bionic
ubuntu-x86_64: DISTRO := ubuntu
ubuntu-x86_64: TAG := ubuntu-x86_64
ubuntu-x86_64: normal-build

alpine-x86_64: BASE_IMAGE := alpine:latest
alpine-x86_64: DISTRO := alpine
alpine-x86_64: TAG := alpine-x86_64
alpine-x86_64: normal-build

normal-build: build push

ubuntu-arm64v8: BASE_IMAGE := arm64v8/ubuntu:bionic
ubuntu-arm64v8: DISTRO := ubuntu
ubuntu-arm64v8: TAG := ubuntu-arm64v8
ubuntu-arm64v8: QEMU_ARCH := aarch64
ubuntu-arm64v8: wrapped-build

alpine-arm64v8: BASE_IMAGE := arm64v8/alpine:latest
alpine-arm64v8: DISTRO := alpine
alpine-arm64v8: TAG := alpine-arm64v8
alpine-arm64v8: QEMU_ARCH := aarch64
alpine-arm64v8: wrapped-build

wrapped-build: qemu-wrap build push

x86_64_qemu-%-static.tar.gz:
	curl -LO https://github.com/multiarch/qemu-user-static/releases/download/v$(QEMU_STATIC_VERSION)/$@

qemu-%-static: x86_64_qemu-%-static.tar.gz
	tar xzf $?

qemu-wrap: DOCKER_FILE := $(shell mktemp)
qemu-wrap:
	$(MAKE) qemu-$(QEMU_ARCH)-static
	sed 's!%%BASE_IMAGE%%!$(BASE_IMAGE)!g' qemu-wrapper/Dockerfile.tmpl > $(DOCKER_FILE)
	docker build --pull --build-arg QEMU_ARCH=$(QEMU_ARCH) -t $(BASE_IMAGE) -f $(DOCKER_FILE) .
	rm -f qemu-$(QEMU_ARCH)-static

build: DOCKER_FILE := $(shell mktemp)
build:
	sed -e 's!%%BASE_IMAGE%%!$(BASE_IMAGE)!g' \
		Dockerfile.$(DISTRO).tmpl > $(DOCKER_FILE)
	docker build \
		--build-arg ERLANG_VER=$(ERLANG_VER) \
		--build-arg ELIXIR_VER=$(ELIXIR_VER) \
		--build-arg LABEL_VCS_REF=`git rev-parse --short HEAD` \
		--build-arg LABEL_BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		-t graffic/elixir:$(TAG) \
		-f $(DOCKER_FILE) .
	
push:
	docker push graffic/elixir:$(TAG)

register:
	docker run --rm --privileged multiarch/qemu-user-static:register -c yes

clean:
	rm -f qemu-*-static qemu-*-static.tar.gz
