#!/bin/bash
set -e

# 載入設定
source "$(dirname "$0")/config.conf"

LogFile="pull_errors.log"
> "$LogFile"

# 將 Images 拆成陣列
read -ra images <<< "$Images"

for image in "${images[@]}"; do
  echo "[Pull] Pulling image: $image"
  if ! docker pull "$image"; then
    echo "❌ Failed to pull image: $image"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed to pull image: $image" >> "$LogFile"
    continue
  fi
  echo "[Pull] ✅ Success: $image"
done
