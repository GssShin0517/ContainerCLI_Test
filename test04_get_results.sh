#!/bin/bash
set -e

# 載入 config & API functions
source "$(dirname "$0")/config.conf"
source "$(dirname "$0")/newapi.sh"

images=("ubuntu:20.04" "alpine:3.14")

echo "[Step2] 取得 Access Token..."
get_AccessToken

echo "[Step2] 取得最新掃描 ID..."
get_LastScanId

for image in "${images[@]}"; do
  echo "[Step2] 下載掃描結果 for $image"
  get_ScanResult "$image"
done

echo "[Step2] 所有結果已存到 reports/"
