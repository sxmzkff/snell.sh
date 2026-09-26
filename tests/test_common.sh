#!/bin/bash
# 公共库单元测试：验证 src/lib/common.sh 中的纯函数。
# 用法：./run.sh
set -u

PASS=0; FAIL=0
assert_eq() {  # assert_eq <描述> <期望> <实际>
    if [ "$2" = "$3" ]; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "FAIL: $1"
        echo "  期望: $2"
        echo "  实际: $3"
    fi
}

# 加载被测库（mock 颜色变量与外部依赖）
RED=''; GREEN=''; YELLOW=''; CYAN=''; RESET=''
SNELL_CONF_DIR="/etc/snell"
SCRIPT_SELF_URL="https://example.com/snell.sh"
# 隔离：不执行 main，只 source 函数定义
# shellcheck disable=SC1091
. "$(dirname "$0")/../src/lib/common.sh"

echo "=== snell_version_sort_key ==="
assert_eq "正式版排序" "006.000.000.3.0000" "$(snell_version_sort_key v6.0.0)"
assert_eq "大写V" "006.000.000.3.0000" "$(snell_version_sort_key V6.0.0)"
assert_eq "beta小于rc" "1" "$( [ "$(snell_version_sort_key 6.0.0b4)" \< "$(snell_version_sort_key 6.0.0rc)" ] && echo 1 || echo 0 )"
assert_eq "rc小于正式版" "1" "$( [ "$(snell_version_sort_key 6.0.0rc2)" \< "$(snell_version_sort_key 6.0.0)" ] && echo 1 || echo 0 )"
assert_eq "版本号补零" "005.000.001.3.0000" "$(snell_version_sort_key v5.0.1)"

echo "=== version_greater_equal ==="
assert_eq "相等" "0" "$(version_greater_equal v5.0.1 v5.0.1; echo $?)"
assert_eq "大于" "0" "$(version_greater_equal v6.0.0 v5.0.1; echo $?)"
assert_eq "小于" "1" "$(version_greater_equal v4.0.0 v5.0.1; echo $?)"

echo "=== pick_latest_snell_version ==="
NOTES="snell-server-v6.0.0-linux-amd64.zip
snell-server-v6.0.1-linux-amd64.zip
snell-server-v5.0.1-linux-amd64.zip"
assert_eq "挑v6最新" "6.0.1" "$(pick_latest_snell_version 6 "$NOTES")"
assert_eq "挑v5最新" "5.0.1" "$(pick_latest_snell_version 5 "$NOTES")"

echo "=== get_latest_snell_v4/v5/v6_version (fallback路径) ==="
# 无网络时应回退到 SNELL_V*_FALLBACK
SNELL_RELEASE_NOTES_URL="https://example.com/notes"
SNELL_RELEASE_NOTES_URL_ZH="https://example.com/notes-zh"
SNELL_V4_FALLBACK="v4.1.1"; SNELL_V5_FALLBACK="v5.0.1"; SNELL_V6_FALLBACK="v6.0.0"
# mock curl 返回空
curl() { return 1; }
assert_eq "v4回退" "v4.1.1" "$(get_latest_snell_v4_version)"
assert_eq "v5回退" "v5.0.1" "$(get_latest_snell_v5_version)"
assert_eq "v6回退" "v6.0.0" "$(get_latest_snell_v6_version)"
unset -f curl

echo "=== check_root (非root时) ==="
if [ "$(id -u)" -ne 0 ]; then
    assert_eq "非root退出码1" "1" "$(check_root >/dev/null 2>&1; echo $?)"
else
    echo "SKIP: 当前为root，跳过非root测试"
fi

echo ""
echo "通过: $PASS, 失败: $FAIL"
[ "$FAIL" -eq 0 ]
