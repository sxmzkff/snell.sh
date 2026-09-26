#!/bin/bash
# 构建脚本：将 src/ 下的源码打包成 dist/ 下的单文件分发脚本。
#
# 原理：src/scripts/*.sh 中的 `### @include ../lib/common.sh` 标记行
#       会被替换为 src/lib/common.sh 的实际内容。用户拿到的仍是
#       零依赖的单文件脚本，分发 URL 不变。
#
# 用法：./build.sh
# 产物：dist/snell.sh dist/snell-centos.sh dist/snell-alpine.sh dist/snell-docker.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SRC="$ROOT/src"
DIST="$ROOT/dist"
LIB="$SRC/lib/common.sh"
MARKER='### @include ../lib/common.sh'

mkdir -p "$DIST"

for src_file in "$SRC"/scripts/*.sh; do
    name="$(basename "$src_file")"
    dest="$DIST/$name"

    if ! grep -qF "$MARKER" "$src_file"; then
        echo "跳过 $name：未找到 @include 标记" >&2
        continue
    fi

    # 用 awk 做标记替换（避免 sed 转义问题）
    awk -v marker="$MARKER" -v lib="$LIB" '
        $0 == marker {
            while ((getline line < lib) > 0) print line
            close(lib)
            next
        }
        { print }
    ' "$src_file" > "$dest"

    chmod +x "$dest"
    echo "构建 $name -> dist/$name"
done

# 校验：所有产物必须通过 bash 与 sh 语法检查
echo "--- 语法校验 ---"
bash -n "$LIB"
sh -n "$LIB"
for f in "$DIST"/*.sh; do
    bash -n "$f" || { echo "FAIL: $f (bash)"; exit 1; }
    # 只有 #!/bin/sh 的脚本才需要过 POSIX sh 检查
    if head -1 "$f" | grep -q '^#!/bin/sh$'; then
        sh -n "$f" || { echo "FAIL: $f (sh)"; exit 1; }
    fi
    echo "OK: $(basename "$f")"
done

echo "构建完成。"
