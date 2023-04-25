.DEFAULT_GOAL := tag

tag: MUSL_CROSS_MAKE_VER=$(shell cat Dockerfile | grep "ENV MUSL_CROSS_MAKE_VER" | sed -e 's,ENV MUSL_CROSS_MAKE_VER=\(.*\),\1,' | tr -d '\n')
tag: ZLIB_VER=$(shell cat Dockerfile | grep "ENV ZLIB_VER" | sed -e 's,ENV ZLIB_VER=\(.*\),\1,' | tr -d '\n')
tag: SSL_VER=$(shell cat Dockerfile | grep "ENV SSL_VER" | sed -e 's,ENV SSL_VER=\(.*\),\1,' | tr -d '\n')
tag: CURL_VER=$(shell cat Dockerfile | grep "ENV CURL_VER" | sed -e 's,ENV CURL_VER=\(.*\),\1,' | tr -d '\n')
tag: VERSION=musl_$(MUSL_CROSS_MAKE_VER)_zlib_$(ZLIB_VER)_ssl_$(SSL_VER)_curl_$(CURL_VER)
tag: NEXT_REVISION=$(shell echo $$(( $(shell git tag -l | grep $(VERSION) | sort -r | head -n 1 | sed -e 's,.*_\(.*\),\1,') + 1 )))
tag:
	git tag $(VERSION)_$(NEXT_REVISION) HEAD
	git push origin $(VERSION)_$(NEXT_REVISION)

test_x86_64:
	docker build . -t ghcr.io/chipp/build.musl.x86_64_musl:test \
		--build-arg TARGET=x86_64-unknown-linux-musl \
		--build-arg OPENSSL_ARCH=linux-x86_64 \
		--progress=plain

test_armv7:
	docker build . -t ghcr.io/chipp/build.musl.armv7_musl:test \
		--build-arg TARGET=armv7-unknown-linux-musleabihf \
		--build-arg OPENSSL_ARCH=linux-generic32 \
		--build-arg ADDITIONAL_LIBS="-latomic" \
		--progress=plain

test: test_x86_64 test_armv7
