#!/bin/bash
set -e

try() {
  "$@"
  local status=$?
  if [[ $status -ne 0 ]]; then
    echo "❌ 發生錯誤: $1"
    exit $status
  fi
}

echo "[Main] Step0 檢查環境"
try bash test00_env_check.sh

echo "[Main] Step1 建立Cx Configure"
try bash test01_cxconfigure.sh

echo "[Main] Step2 拉取 images"
try bash test02_pull_images.sh

echo "[Main] Step3 掃描images"
try bash test03_scan.sh

echo "[Main] Step4 透過API取得結果"
try bash test04_get_results.sh

echo "[Main] Step5 刪除現有的images"
try bash test05_cleanup.sh

echo "✅ 所有流程完成!"
