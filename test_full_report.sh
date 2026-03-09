#!/bin/bash
set -e

# === 匯入 API 函數與 config ===
ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ScriptDir/config.conf"
source "$ScriptDir/newapi.sh"   # 這裡是你的 API 函式（含 create_Report / get_ReportStatus / download_Report）

# === 1️⃣ 取得 scan_id ===
if [[ -z "$1" ]]; then
    echo "⏳ Fetching last scan ID..."
    get_AccessToken        # 先拿 Token
    get_LastScanId         # 從專案抓最後一次掃描
    scan_id="$LastScanId"
else
    scan_id="$1"
fi

if [[ -z "$scan_id" || "$scan_id" == "null" ]]; then
    echo "❌ No scan_id available, cannot proceed."
    exit 1
fi

echo "✅ Using scan_id: $scan_id"

# === 2️⃣ 建立報告 ===
report_id=$(create_Report "$scan_id" pdf cli)

if [[ -z "$report_id" || "$report_id" == "null" ]]; then
    echo "❌ Failed to create report!"
    exit 1
fi

echo "✅ Report created → ID: $report_id"

# === 3️⃣ 等待報告完成（最多 10 分鐘） ===
max_attempts=20    # 20 次 * 30 秒 = 10 分鐘
attempt=1
status="requested"

while [[ $attempt -le $max_attempts ]]; do
    echo "⏳ Polling report status (attempt $attempt/$max_attempts)..."

    status_response=$(get_ReportStatus "$report_id")
    status=$(echo "$status_response" | jq -r ".status")

    echo "📊 Report status: $status"

    if [[ "$status" == "completed" ]]; then
        echo "✅ Report is ready!"
        break
    elif [[ "$status" == "failed" ]]; then
        echo "❌ Report generation failed!"
        exit 1
    fi

    echo "⏳ Still $status, waiting 30s..."
    sleep 30
    attempt=$((attempt + 1))
done

if [[ "$status" != "completed" ]]; then
    echo "❌ Report not ready after $max_attempts attempts."
    exit 1
fi

# === 4️⃣ 下載報告 ===
timestamp=$(date +%Y%m%d_%H%M%S)
output_file="scan_report_${timestamp}.pdf"

download_Report "$report_id" "$output_file"

echo "🎉 All done! Report saved → $output_file"
