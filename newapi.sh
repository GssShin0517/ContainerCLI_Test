ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ConfigFile="$ScriptDir/config.conf"

if [[ -f "$ConfigFile" ]]; then
    source "$ConfigFile"
else
    echo "找不到設定檔: $ConfigFile"
    exit 1
fi


get_AccessToken() {
    if [ -z "$Url"]; then
        echo "❌ Error: Url or ApiKey is not set. Please check config.conf"
        exit 1
    fi

    Response=$(curl -s --request POST "$Url" \
        --header "Content-Type: application/x-www-form-urlencoded" \
        --header "Accept: application/json" \
        --data-urlencode "client_id=$ClientId" \
        --data-urlencode "grant_type=client_credentials" \
        --data-urlencode "client_secret=$ClientSecret")

    AccessToken=$(echo "$Response" | jq -r ".access_token")
    TokenType=$(echo "$Response" | jq -r ".token_type")

    if [[ -z "$AccessToken" || "$AccessToken" == "null" ]]; then
        echo "❌ Failed to retrieve access token. Please check your ApiKey or Url."
        echo "👉 Raw response: $Response"
        exit 1
    fi

    echo "✅ Access token retrieved successfully."
    echo "AccessToken=$AccessToken"
    echo "TokenType=$TokenType"
}


get_LastScanId() {
    if [[ -z "$ProjectId" || -z "$AccessToken" || -z "$TokenType" ]]; then
        echo "Error: Missing required variables (ProjectId, AccessToken, or TokenType)"
        exit 1
    fi

    Response=$(curl -s --request GET \
        --url "https://sng.ast.checkmarx.net/api/projects/last-scan?project-ids=$ProjectId" \
        --header "Accept: application/json" \
        --header "Authorization: $TokenType $AccessToken" \
        --header "CorrelationId:")

    LastScanStatus=$(echo "$Response" | jq -r --arg pid "$ProjectId" '.[$pid].status')
    LastScanId=$(echo "$Response" | jq -r --arg pid "$ProjectId" '.[$pid].id')

    if [[ -z "$LastScanId" || "$LastScanId" == "null" ]]; then
        echo "Error: Failed to retrieve last scan ID or status."
        echo "Raw response: $Response"
        exit 1
    fi

    echo "Last scan status: $LastScanStatus"
    echo "Last scan ID: $LastScanId"
}

get_ScanResult() {
    local image_name="$1"

    if [[ -z "$LastScanId" || -z "$AccessToken" || -z "$TokenType" ]]; then
        echo "Error: Missing required variables (LastScanId, AccessToken, or TokenType)"
        exit 1
    fi

    Response=$(curl -s --request GET \
        --url "https://sng.ast.checkmarx.net/api/results/?scan-id=$LastScanId&limit=10000" \
        --header "Accept: application/json" \
        --header "Authorization: $TokenType $AccessToken" \
        --header "CorrelationId:")

    if [[ -z "$Response" || "$Response" == "null" ]]; then
        echo "Error: Failed to retrieve scan results for image: $image_name"
        exit 1
    fi

    safe_name=$(echo "$image_name" | sed 's/[:\/]/_/g')
    output_file="reports/scan_result_${safe_name}.json" 

    echo "$Response" > "$output_file"
    echo "Scan results saved to $output_file"
}

create_Report() {
    local scan_id="$1"
    local report_format="${2:-pdf}"       # 預設 pdf，可改成 csv/json
    local report_access="${3:-cli}"       # 預設 cli，可是 ui 或 email
    local report_name="improved-scan-report" # 產生新版 Scan Report

    if [[ -z "$scan_id" || -z "$ProjectId" || -z "$AccessToken" || -z "$TokenType" ]]; then
        echo "❌ Error: Missing required variables (scan_id, ProjectId, AccessToken, TokenType)"
        exit 1
    fi

    # 準備 payload
    payload=$(jq -n \
        --arg scanId "$scan_id" \
        --arg projectId "$ProjectId" \
        --arg branchName "$Branch" \
        --arg fileFormat "$report_format" \
        --arg reportType "$report_access" \
        --arg reportName "$report_name" \
        '{
            "fileFormat": $fileFormat,
            "reportType": $reportType,
            "reportName": $reportName,
            "data": {
                "scanId": $scanId,
                "projectId": $projectId,
                "branchName": $branchName,
                "sections": ["scan-information","results-overview","scan-results","vulnerability-details"],
                "scanners": ["sca","kics","containers"]
            }
        }'
    )

    echo "📤 Creating report for scan: $scan_id"

    response=$(curl -s --request POST \
        --url "https://sng.ast.checkmarx.net/api/reports/" \
        --header "Accept: application/json; version=1.0" \
        --header "Authorization: $TokenType $AccessToken" \
        --header "Content-Type: application/json; version=1.0" \
        --data "$payload"
    )

    report_id=$(echo "$response" | jq -r ".reportId")

    if [[ -z "$report_id" || "$report_id" == "null" ]]; then
        echo "❌ Failed to create report. Raw response: $response"
        exit 1
    fi

    echo "✅ Report created successfully!"
    echo "Report ID: $report_id"

    # 回傳 report_id
    echo "$report_id"
}

get_ReportStatus() {
    local report_id="$1"

    if [[ -z "$report_id" || -z "$AccessToken" || -z "$TokenType" ]]; then
        echo "❌ Error: Missing required variables (report_id, AccessToken, TokenType)"
        exit 1
    fi

    echo "🔍 Checking report status for ID: $report_id"

    response=$(curl -s --request GET \
        --url "https://sng.ast.checkmarx.net/api/reports/$report_id" \
        --header "Accept: application/json; version=1.0" \
        --header "Authorization: $TokenType $AccessToken"
    )

    status=$(echo "$response" | jq -r ".status")
    url=$(echo "$response" | jq -r ".url")

    if [[ -z "$status" || "$status" == "null" ]]; then
        echo "❌ Failed to get report status. Raw response: $response"
        exit 1
    fi

    echo "📊 Report status: $status"

    if [[ "$status" == "completed" ]]; then
        echo "✅ Report is ready!"
        if [[ "$url" != "null" && -n "$url" ]]; then
            echo "📎 Download URL: $url"
        fi
    elif [[ "$status" == "failed" ]]; then
        echo "❌ Report generation failed!"
        echo "Raw response: $response"
        exit 1
    else
        echo "⏳ Report still in progress (status: $status)"
    fi

    # 回傳完整 JSON 給上層使用
    echo "$response"
}

download_Report() {
    local report_id="$1"
    local output_file="${2:-report.pdf}"

    if [[ -z "$report_id" || -z "$AccessToken" || -z "$TokenType" ]]; then
        echo "❌ Error: Missing required variables (report_id, AccessToken, TokenType)"
        exit 1
    fi

    echo "⬇️  Downloading report ID: $report_id ..."

    curl -s -L --request GET \
        --url "https://sng.ast.checkmarx.net/api/reports/$report_id/download" \
        --header "Accept: application/json; version=1.0" \
        --header "Authorization: $TokenType $AccessToken" \
        --output "$output_file"

    if [[ -s "$output_file" ]]; then
        echo "✅ Report downloaded successfully → $output_file"
    else
        echo "❌ Download failed! File is empty or request failed."
        return 1
    fi
}
