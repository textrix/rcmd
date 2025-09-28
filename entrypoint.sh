#!/bin/sh
set -e

TARGET_UID="${PUID:-1000}"
TARGET_GID="${PGID:-1000}"
TARGET_USER="${USER_NAME:-dev}"
TARGET_GROUP="devgrp"

# 그룹
EXIST_G="$(awk -F: -v gid="$TARGET_GID" '($3==gid){print $1; exit}' /etc/group || true)"
if [ -n "$EXIST_G" ]; then
  TARGET_GROUP="$EXIST_G"
else
  addgroup -g "$TARGET_GID" "$TARGET_GROUP" 2>/dev/null || true
fi

# 사용자
EXIST_U="$(awk -F: -v uid="$TARGET_UID" '($3==uid){print $1; exit}' /etc/passwd || true)"
if [ -n "$EXIST_U" ]; then
  TARGET_USER="$EXIST_U"
else
  adduser -D -u "$TARGET_UID" -G "$TARGET_GROUP" "$TARGET_USER"
fi

# /work 권한 (루트일 때만 한 번 정리)
if [ -d /work ]; then
  WU="$(stat -c %u /work 2>/dev/null || echo 0)"
  [ "$WU" -eq 0 ] && chown "$TARGET_UID:$TARGET_GID" /work || true
fi

cd /work
# ★ 'sh -lc "<CMD>"' 형태로 들어온 경우를 정확히 처리
if [ "$1" = "sh" ] && [ "$2" = "-lc" ] && [ -n "$3" ]; then
  exec su -s /bin/sh "$TARGET_USER" -c "$3"
elif [ "$#" -gt 0 ]; then
  exec su -s /bin/sh "$TARGET_USER" -c "$*"
else
  exec su -s /bin/sh "$TARGET_USER"
fi
