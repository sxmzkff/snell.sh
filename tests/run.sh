#!/bin/bash
# 测试入口：跑全部测试
# 用法：./run.sh
set -e
cd "$(dirname "$0")"
chmod +x test_common.sh
./test_common.sh
