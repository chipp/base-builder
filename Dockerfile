FROM debian:bookworm-slim

ARG TARGET=x86_64-unknown-linux-musl

RUN apt-get update && apt-get install -y \
    autoconf \
    automake \
    build-essential \
    bzip2 \
    ca-certificates \
    cmake \
    curl \
    file \
    gettext \
    libtool \
    musl \
    ninja-build \
    patch \
    pkg-config \
    python3 \
    python3-venv \
    unzip \
    xutils-dev \
    xz-utils \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

COPY musl-cross-make musl-cross-make
RUN cd musl-cross-make && \
    TARGET=$TARGET make -j$(nproc) install && \
    cd .. && rm -rf musl-cross-make && \
    find /musl -name "*.la" -print0 | xargs -0 sed -i "s|libdir='/${TARGET}/lib'|libdir='/musl/${TARGET}/lib'|g"

ENV TARGET=${TARGET} \
    PREFIX=/musl/$TARGET \
    LD_LIBRARY_PATH=/musl/$TARGET \
    PATH=/musl/bin:/python/bin:$PATH

COPY meson/${TARGET}.cross /musl/meson.cross
RUN python3 -m venv python && pip3 install meson

ENV TARGET_CC=/musl/bin/$TARGET-gcc \
    TARGET_CXX=/musl/bin/$TARGET-g++ \
    TARGET_C_INCLUDE_PATH=$PREFIX/include/

ENV CC=$TARGET_CC \
    CXX=$TARGET_CXX \
    C_INCLUDE_PATH=$TARGET_C_INCLUDE_PATH \
    CHOST=$TARGET \
    CROSS_PREFIX=$TARGET- \
    LDFLAGS="-L$PREFIX/lib -L$PREFIX/lib64" \
    CPPFLAGS="-I$PREFIX/include" \
    PKG_CONFIG_ALLOW_CROSS=true \
    PKG_CONFIG_ALL_STATIC=true \
    PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig
