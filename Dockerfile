FROM debian:buster-slim

ARG TARGET=x86_64-unknown-linux-musl
ARG OPENSSL_ARCH=linux-x86_64

RUN apt-get update && apt-get install -y \
  curl \
  xutils-dev \
  unzip \
  xz-utils \
  bzip2 \
  patch \
  build-essential \
  file \
  pkg-config \
  ca-certificates \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

COPY musl-cross-make musl-cross-make
RUN cd musl-cross-make && \
  TARGET=$TARGET make -j$(nproc) install && \
  cd .. && rm -rf musl-cross-make

ARG ADDITIONAL_LIBS

ENV TARGET=${TARGET} \
  OPENSSL_ARCH=${OPENSSL_ARCH} \
  PREFIX=/musl/$TARGET \
  LD_LIBRARY_PATH=$PREFIX \
  PATH=/musl/bin:$PATH

ENV TARGET_CC=/musl/bin/$TARGET-gcc \
  TARGET_CXX=/musl/bin/$TARGET-g++ \
  TARGET_C_INCLUDE_PATH=$PREFIX/include/

ENV CC=$TARGET_CC \
  CXX=$TARGET_CXX \
  C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH \
  CHOST=$TARGET \
  CROSS_PREFIX=$TARGET- \
  LDFLAGS="-L$PREFIX/lib -L$PREFIX/lib64" \
  CFLAGS="-I$PREFIX/include" \
  CPPFLAGS="-I$PREFIX/include" \
  PKG_CONFIG_ALLOW_CROSS=true \
  PKG_CONFIG_ALL_STATIC=true \
  PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig

ENV ZLIB_VER=1.3
ENV ZLIB_SHA256="ff0ba4c292013dbc27530b3a81e1f9a813cd39de01ca5e0f8bf355702efa593e"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
  tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
  CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
  CHOST=arm ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER=3.0.11
ENV SSL_SHA256="b3425d3bb4a2218d0697eb41f7fc0cdede016ed19ca49d168b78e8d947887f55"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
  echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
  tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
  CC=gcc CXX=g++ ./Configure -fPIC --cross-compile-prefix=${TARGET}- --prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} no-zlib no-shared no-module $OPENSSL_ARCH && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install_sw && \
  cd .. && rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz

ENV CURL_VER=8.3.0
ENV CURL_SHA256="d3a19aeea301085a56c32bc0f7d924a818a7893af253e41505d1e26d7db8e95a"
RUN curl -sSL -O https://curl.haxx.se/download/curl-$CURL_VER.tar.gz && \
  echo "$CURL_SHA256  curl-$CURL_VER.tar.gz" | sha256sum -c - && \
  tar xfz curl-${CURL_VER}.tar.gz && cd curl-$CURL_VER && \
  CC="$CC -fPIC -pie" LIBS="-ldl ${ADDITIONAL_LIBS}" \
  ./configure --enable-shared=no --with-zlib --with-openssl --enable-optimize --prefix=$PREFIX \
  --with-ca-path=/etc/ssl/certs/ --with-ca-bundle=/etc/ssl/certs/ca-certificates.crt --without-ca-fallback \
  --disable-shared --disable-ldap --disable-sspi --without-librtmp --disable-ftp \
  --disable-file --disable-dict --disable-telnet --disable-tftp --disable-manual --disable-ldaps \
  --disable-dependency-tracking --disable-rtsp --disable-pop3  --disable-imap --disable-smtp \
  --disable-gopher --disable-smb --without-libidn --disable-proxy --host armv7 && \
  make -j$(nproc) curl_LDFLAGS="-all-static" && make install && \
  cd .. && rm -rf curl-$CURL_VER curl-$CURL_VER.tar.gz

ENV OPENSSL_STATIC=1 \
  OPENSSL_DIR=$PREFIX \
  OPENSSL_INCLUDE_DIR=$PREFIX/include/ \
  DEP_OPENSSL_INCLUDE=$PREFIX/include/ \
  OPENSSL_LIB_DIR=$PREFIX/lib64/ \
  LIBZ_SYS_STATIC=1 \
  SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  SSL_CERT_DIR=/etc/ssl/certs
