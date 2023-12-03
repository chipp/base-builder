FROM debian:buster-slim

ARG TARGET=x86_64-unknown-linux-musl

RUN apt-get update && apt-get install -y \
  curl \
  xutils-dev \
  unzip \
  xz-utils \
  bzip2 \
  patch \
  build-essential \
  cmake \
  file \
  pkg-config \
  ca-certificates \
  --no-install-recommends && \
  rm -rf /var/lib/apt/lists/*

COPY musl-cross-make musl-cross-make
RUN cd musl-cross-make && \
  TARGET=$TARGET make -j$(nproc) install && \
  cd .. && rm -rf musl-cross-make

ENV TARGET=${TARGET} \
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
