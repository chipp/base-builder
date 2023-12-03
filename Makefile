.DEFAULT_GOAL := tag

tag: MUSL_VER=$(shell cat musl-cross-make/config.mak | grep "MUSL_VER" | sed -e 's,MUSL_VER = \(.*\),\1,' | tr -d '\n')
tag: VERSION=musl_$(MUSL_VER)
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(VERSION)_$(NEXT_REVISION)

test_x86_64:
	docker build . -t ghcr.io/chipp/build.musl.x86_64_musl:test \
		--build-arg TARGET=x86_64-unknown-linux-musl \
		--load \
		--progress=plain

test_armv7:
	docker build . -t ghcr.io/chipp/build.musl.armv7_musl:test \
		--build-arg TARGET=armv7-unknown-linux-musleabihf \
		--load \
		--progress=plain

test_arm64:
	docker build . -t ghcr.io/chipp/build.musl.arm64_musl:test \
		--build-arg TARGET=aarch64-linux-musl \
		--load \
		--progress=plain

test: test_x86_64 test_armv7 test_arm64

release_x86_64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_x86_64:
	docker build . \
		--push \
		--build-arg TARGET=x86_64-unknown-linux-musl \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.musl.x86_64_musl:${VERSION} \
		--tag ghcr.io/chipp/build.musl.x86_64_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.musl.x86_64_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.musl.x86_64_musl:cache,mode=max

release_armv7: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_armv7:
	docker build . \
		--push \
		--build-arg TARGET=armv7-unknown-linux-musleabihf \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.musl.armv7_musl:${VERSION} \
		--tag ghcr.io/chipp/build.musl.armv7_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.musl.armv7_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.musl.armv7_musl:cache,mode=max

release_arm64: VERSION=$(shell git tag --sort=committerdate | tail -1 | tr -d '\n')
release_arm64:
	docker build . \
		--push \
		--build-arg TARGET=aarch64-linux-musl \
		--label "org.opencontainers.image.source=https://github.com/chipp/base-builder" \
		--platform linux/amd64,linux/arm64 \
		--tag ghcr.io/chipp/build.musl.arm64_musl:${VERSION} \
		--tag ghcr.io/chipp/build.musl.arm64_musl:latest \
		--cache-from=type=registry,ref=ghcr.io/chipp/build.musl.arm64_musl:cache \
		--cache-to=type=registry,ref=ghcr.io/chipp/build.musl.arm64_musl:cache,mode=max

release: release_x86_64 release_armv7 release_arm64
