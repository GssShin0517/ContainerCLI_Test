#!/bin/bash
set -e

ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ConfigFile="$ScriptDir/config.conf"
ApiFunctions="$ScriptDir/newapi.sh"

echo "[Step 0] 檢查環境 & 載入設定檔..."

if [[ -f "$ConfigFile" ]]; then
    source "$ConfigFile"
    echo "✅ 載入 config.conf 成功"
else
    echo "❌ Config file not found: $ConfigFile"
    exit 1
fi

if [[ -f "$ApiFunctions" ]]; then
    source "$ApiFunctions"
    echo "✅ 載入 API functions 成功"
else
    echo "❌ API functions file not found: $ApiFunctions"
    exit 1
fi

mkdir -p reports
touch pull_errors.log
echo "[OK] 環境初始化完成"
