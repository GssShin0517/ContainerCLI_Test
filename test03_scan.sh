#!/bin/bash
set -e

# 載入設定
source "$(dirname "$0")/config.conf"

# 將 Images 拆成陣列
read -ra images <<< "$Images"

for image in "${images[@]}"; do
  # 確認本地是否存在該 image
  if ! docker image inspect "$image" > /dev/null 2>&1; then
    echo "⚠️  Image not found locally, skipping scan: $image"
    continue
  fi

  echo "[Scan] Scanning image: $image"
  ./cx scan create \
    --project-name "$ProjectName" \
    -s ./empty \
    --branch "$Branch" \
    --scan-types "$ScanType" \
    --container-images "$image" \
    --debug

  echo "[Scan] ✅ 完成掃描: $image"
  echo "--------------------------------------------"
done
