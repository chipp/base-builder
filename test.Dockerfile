ARG VARIANT

FROM ghcr.io/chipp/build.musl.${VARIANT}:test

RUN apt-get update && apt-get install -y \
    git \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

ENV GLIB_VER="2.80.3"\
    GLIB_SHA="3947a0eaddd0f3613d0230bb246d0c69e46142c19022f5c4b1b2e3cba236d417"

RUN GLIB_MAJOR_MINOR=$(echo $GLIB_VER | cut -d. -f1-2) && \
    curl -OL https://download.gnome.org/sources/glib/${GLIB_MAJOR_MINOR}/glib-${GLIB_VER}.tar.xz && \
    echo "${GLIB_SHA}  glib-${GLIB_VER}.tar.xz" | sha256sum -c - && \
    tar xfJ glib-${GLIB_VER}.tar.xz && \
    cd glib-${GLIB_VER} && \
    pip3 install packaging && \
    meson setup --cross-file /musl/meson.cross --prefix $PREFIX --pkg-config-path $PKG_CONFIG_PATH \
    --default-library static -Dlibmount=disabled -Dselinux=disabled \
    -Dtests=false _build && \
    meson compile -C _build && \
    meson install -C _build && \
    cd .. && rm -rf glib-${GLIB_VER}.tar.xz glib-${GLIB_VER}
