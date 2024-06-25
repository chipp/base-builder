.DEFAULT_GOAL := tag

tag: MUSL_VER=$(shell cat musl-cross-make/config.mak | grep "MUSL_VER" | sed -e 's,MUSL_VER = \(.*\),\1,' | tr -d '\n')
tag: VERSION=musl_$(MUSL_VER)
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(VERSION)_$(NEXT_REVISION)

test_x86_64: TARGET=x86_64-unknown-linux-musl
test_x86_64: VARIANT=x86_64_musl
test_x86_64: IMAGE_ID=ghcr.io/chipp/build.musl.${VARIANT}
test_x86_64:
	docker buildx build . \
		--push \
		--build-arg TARGET="${TARGET}" \
		--tag ${IMAGE_ID}:test-linux-arm64 \
		--cache-from=type=registry,ref=${IMAGE_ID}:cache-linux-arm64

	docker buildx build . \
		--file test.Dockerfile \
		--builder container \
		--load \
		--build-arg IMAGE=${IMAGE_ID}:test-linux-arm64 \
		--tag ${IMAGE_ID}:validate

	docker rmi ${IMAGE_ID}:validate

test_armv7: TARGET=armv7-unknown-linux-musleabihf
test_armv7: VARIANT=armv7_musl
test_armv7: IMAGE_ID=ghcr.io/chipp/build.musl.${VARIANT}
test_armv7:
	docker buildx build . \
		--push \
		--build-arg TARGET="${TARGET}" \
		--tag ${IMAGE_ID}:test-linux-arm64 \
		--cache-from=type=registry,ref=${IMAGE_ID}:cache-linux-arm64

	docker buildx build . \
		--file test.Dockerfile \
		--load \
		--build-arg IMAGE=${IMAGE_ID}:test-linux-arm64 \
		--tag ${IMAGE_ID}:validate

	docker rmi ${IMAGE_ID}:validate

test_arm64: TARGET=aarch64-linux-musl
test_arm64: VARIANT=arm64_musl
test_arm64: IMAGE_ID=ghcr.io/chipp/build.musl.${VARIANT}
test_arm64:
	docker buildx build . \
		--push \
		--build-arg TARGET="${TARGET}" \
		--tag ${IMAGE_ID}:test-linux-arm64 \
		--cache-from=type=registry,ref=${IMAGE_ID}:cache-linux-arm64

	docker buildx build . \
		--file test.Dockerfile \
		--load \
		--build-arg IMAGE=${IMAGE_ID}:test-linux-arm64 \
		--tag ${IMAGE_ID}:validate

	docker rmi ${IMAGE_ID}:validate

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
