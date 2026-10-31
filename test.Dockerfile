FROM base-builder-rs

RUN apt-get update && apt-get install -y \
    git \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV GLIB_VER="2.80.3"\
    GLIB_SHA="3947a0eaddd0f3613d0230bb246d0c69e46142c19022f5c4b1b2e3cba236d417"

RUN --mount=from=ghcr.io/astral-sh/uv:0.13.6,source=/uv,target=/usr/local/bin/uv \
    --mount=type=bind,source=zlib.wrap,target=/tmp/zlib.wrap \
    GLIB_MAJOR_MINOR=$(echo $GLIB_VER | cut -d. -f1-2) && \
    curl -OL https://download.gnome.org/sources/glib/${GLIB_MAJOR_MINOR}/glib-${GLIB_VER}.tar.xz && \
    echo "${GLIB_SHA}  glib-${GLIB_VER}.tar.xz" | sha256sum -c - && \
    tar xfJ glib-${GLIB_VER}.tar.xz && \
    cd glib-${GLIB_VER} && \
    cp /tmp/zlib.wrap subprojects/zlib.wrap && \
    uv pip install --python /python/bin/python packaging==26.3 && \
    meson setup --cross-file /musl/meson.cross --prefix $PREFIX \
    --default-library static -Dlibmount=disabled -Dselinux=disabled \
    -Dtests=false _build && \
    meson compile -C _build && \
    meson install -C _build && \
    cd .. && rm -rf glib-${GLIB_VER}.tar.xz glib-${GLIB_VER}

RUN --mount=type=bind,source=smoke-test.sh,target=/tmp/smoke-test.sh \
    sh /tmp/smoke-test.sh
