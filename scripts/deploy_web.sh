#!/bin/bash
# Web 部署脚本：构建 + 清理无用文件 + 启动本地测试服务器

set -e
cd "$(dirname "$0")/.."

echo "=== 1. 构建 Web 版 ==="
flutter build web

echo ""
echo "=== 2. 清理 Web 端无用文件 ==="
# 移除移动端专属的大文件（Web 端用不到）
rm -f build/web/assets/assets/infiltration.db
echo "  已移除 infiltration.db (164MB)"

echo ""
echo "=== 3. 本地测试 ==="
echo "  启动 http://localhost:8080"
echo "  按 Ctrl+C 停止"
python3 -m http.server 8080 -d build/web
