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

COPY config.mak config.mak

ENV MUSL_CROSS_MAKE_VER=0.9.9
ENV MUSL_CROSS_MAKE_SHA256="6cbe2f6ce92e7f8f3973786aaf0b990d0db380c0e0fc419a7d516df5bb03c891"
RUN curl -sSL -o musl.zip https://github.com/richfelker/musl-cross-make/archive/v$MUSL_CROSS_MAKE_VER.zip && \
  echo "$MUSL_CROSS_MAKE_SHA256  musl.zip" | sha256sum -c -; \
  unzip musl.zip && mv musl-cross-make-${MUSL_CROSS_MAKE_VER} musl-cross-make && cd musl-cross-make && \
  mv ../config.mak ./ && \
  TARGET=$TARGET make -j$(nproc) install > /dev/null && \
  cd .. && rm -rf musl-cross-make musl.zip

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

ENV ZLIB_VER=1.2.13
ENV ZLIB_SHA256="b3a24de97a8fdbc835b9833169501030b8977031bcb54b3b3ac13740f846ab30"
RUN curl -sSL -O https://zlib.net/zlib-$ZLIB_VER.tar.gz && \
  echo "$ZLIB_SHA256  zlib-$ZLIB_VER.tar.gz" | sha256sum -c - && \
  tar xfz zlib-${ZLIB_VER}.tar.gz && cd zlib-$ZLIB_VER && \
  CC="$CC -fPIC -pie" LDFLAGS="-L$PREFIX/lib" CFLAGS="-I$PREFIX/include" \
  CHOST=arm ./configure --static --prefix=$PREFIX && \
  make -j$(nproc) && make install && \
  cd .. && rm -rf zlib-$ZLIB_VER zlib-$ZLIB_VER.tar.gz

ENV SSL_VER=3.0.8
ENV SSL_SHA256="6c13d2bf38fdf31eac3ce2a347073673f5d63263398f1f69d0df4a41253e4b3e"
RUN curl -sSL -O https://www.openssl.org/source/openssl-$SSL_VER.tar.gz && \
  echo "$SSL_SHA256  openssl-$SSL_VER.tar.gz" | sha256sum -c - && \
  tar xfz openssl-${SSL_VER}.tar.gz && cd openssl-$SSL_VER && \
  CC=gcc CXX=g++ ./Configure -fPIC --cross-compile-prefix=${TARGET}- --prefix=$PREFIX --openssldir=$PREFIX/ssl ${ADDITIONAL_LIBS} no-zlib no-shared no-module $OPENSSL_ARCH && \
  env C_INCLUDE_PATH=$PREFIX/include make depend 2> /dev/null && \
  make -j$(nproc) && make install_sw && \
  cd .. && rm -rf openssl-$SSL_VER openssl-$SSL_VER.tar.gz

ENV CURL_VER=8.0.1
ENV CURL_SHA256="5fd29000a4089934f121eff456101f0a5d09e2a3e89da1d714adf06c4be887cb"
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
