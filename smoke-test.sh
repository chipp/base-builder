#!/bin/sh
set -eu

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cat > "$workdir/test.c" <<'EOF'
#include <glib.h>
int main(void) {
    gchar *value = g_strdup("smoke test");
    g_free(value);
    return 0;
}
EOF
cat > "$workdir/test.cpp" <<'EOF'
#include <string>
int main() { return std::string("smoke test").empty(); }
EOF

# pkg-config emits separate compiler and linker arguments intentionally.
# shellcheck disable=SC2046
$CC -static "$workdir/test.c" -o "$workdir/test-c" $(pkg-config --cflags --libs --static glib-2.0)
$CXX -static "$workdir/test.cpp" -o "$workdir/test-cpp"

case "$TARGET" in
    x86_64-unknown-linux-musl) machine='Advanced Micro Devices X86-64'; native=x86_64 ;;
    aarch64-linux-musl) machine='AArch64'; native=aarch64 ;;
    armv7-unknown-linux-musleabihf) machine='ARM'; native=armv7l ;;
    *) echo "Unknown target: $TARGET" >&2; exit 1 ;;
esac

for binary in "$workdir/test-c" "$workdir/test-cpp"; do
    "$CROSS_PREFIX"readelf -h "$binary" | grep -F "Machine:" | grep -F "$machine"
    if "$CROSS_PREFIX"readelf -l "$binary" | grep -q INTERP ||
       "$CROSS_PREFIX"readelf -d "$binary" | grep -q NEEDED; then
        echo "Binary has dynamic dependencies: $binary" >&2
        exit 1
    fi
    if [ "$(uname -m)" = "$native" ]; then
        "$binary"
    fi
done
