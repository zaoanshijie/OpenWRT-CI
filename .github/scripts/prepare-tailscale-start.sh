#!/bin/bash
# SPDX-License-Identifier: MIT
# 把 tailscale 服务的启动顺序从 80 调到 99（排在 network S20 之后、与 tailscale-settings S99 同段）
#
# 说明：
#   /etc/rc.d/S<nn>tailscale 这个软链不是包 Makefile 建的，而是装包时 OpenWrt 按
#   init 脚本里的 START= 自动生成，所以改源文件里的 START 就能得到 S99tailscale。
#   /etc/rc.d 不在 sysupgrade 保留列表里，刷机后会按新镜像重建，不会残留旧的 S80。

set -euo pipefail

INIT_FILE="feeds/packages/net/tailscale/files/tailscale.init"
TARGET_START=99

if [ ! -f "$INIT_FILE" ]; then
	echo "ERROR: 找不到 $INIT_FILE" >&2
	exit 1
fi

BEFORE=$(grep -m1 -E '^START=' "$INIT_FILE" || true)
if [ -z "$BEFORE" ]; then
	echo "ERROR: $INIT_FILE 里没有 START= 定义，上游结构可能变了" >&2
	exit 1
fi

if [ "$BEFORE" = "START=$TARGET_START" ]; then
	echo "tailscale START 已经是 $TARGET_START，跳过"
	exit 0
fi

sed -i -E "s/^START=[0-9]+$/START=$TARGET_START/" "$INIT_FILE"

# 改完必须验证，否则宁可让 CI 失败也不要出个顺序没变的固件
if ! grep -qx "START=$TARGET_START" "$INIT_FILE"; then
	echo "ERROR: 修改 $INIT_FILE 失败，当前内容：" >&2
	grep -n -E '^START=' "$INIT_FILE" >&2 || true
	exit 1
fi

echo "tailscale 启动顺序：$BEFORE -> START=$TARGET_START"
grep -n -E '^START=' "$INIT_FILE"
