#!/bin/bash

# CIS Apache HTTP Server 2.4 Benchmark Audit Script
# Full automated checks with HTML report output

REPORT_DIR="./cis_apache_report"
HTML_REPORT="$REPORT_DIR/apache_cis_report.html"
TMP_RESULT="$REPORT_DIR/tmp_result.csv"
APACHE_CONF=$(apachectl -V | grep SERVER_CONFIG_FILE | cut -d'"' -f2)
APACHE_PREFIX=$(dirname "$APACHE_CONF")

mkdir -p "$REPORT_DIR"
> "$TMP_RESULT"

log_finding() {
  local id="$1"
  local title="$2"
  local risk="$3"
  local status="$4"
  local remediation="$5"
  local notes="$6"
  echo "$id|$title|$risk|$status|$remediation|$notes" >> "$TMP_RESULT"
}

### Automated Checks from CIS Benchmark ###

# 2.2 Log Config Module
check_log_config_module() {
  id="2.2"
  title="Ensure Log Config Module Is Enabled"
  risk="High"
  remediation="Ensure 'LoadModule log_config_module modules/mod_log_config.so' exists"
  status="Fail"
  notes=$(apachectl -M 2>/dev/null | grep log_config_module)
  [[ -n "$notes" ]] && status="Pass"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

# 2.3 WebDAV Disabled
check_webdav_module_disabled() {
  id="2.3"
  title="Ensure WebDAV Modules Are Disabled"
  risk="High"
  remediation="Disable mod_dav and mod_dav_fs"
  notes=$(apachectl -M 2>/dev/null | grep 'dav_')
  status="Pass"
  [[ -n "$notes" ]] && status="Fail"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

# 2.4 Status Module Disabled
check_status_module_disabled() {
  id="2.4"
  title="Ensure Status Module Is Disabled"
  risk="High"
  remediation="Disable mod_status"
  notes=$(apachectl -M 2>/dev/null | grep status_module)
  status="Pass"
  [[ -n "$notes" ]] && status="Fail"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

# 5.4 Default HTML Content Removed
check_default_html_removed() {
  id="5.4"
  title="Ensure Default HTML Content Is Removed"
  risk="Medium"
  remediation="Remove default index.html files and icons"
  notes=$(find /var/www/html -name 'index.html' 2>/dev/null)
  status="Pass"
  [[ -n "$notes" ]] && status="Fail"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

# 7.4 Disable TLSv1.0 and TLSv1.1
check_tls_versions() {
  id="7.4"
  title="Ensure TLSv1.0 and TLSv1.1 Are Disabled"
  risk="High"
  remediation="Use 'SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1'"
  notes=$(grep -i 'SSLProtocol' "$APACHE_CONF" 2>/dev/null | grep -v '#')
  status="Fail"
  [[ "$notes" =~ -TLSv1 ]] && status="Pass"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

# 3.4 Apache Files Owned by Root
check_apache_files_owned_by_root() {
  id="3.4"
  title="Ensure Apache Directories and Files Are Owned By Root"
  risk="High"
  remediation="chown -R root:root $APACHE_PREFIX"
  notes=$(find "$APACHE_PREFIX" ! -user root -ls 2>/dev/null | head -n 10)
  status="Pass"
  [[ -n "$notes" ]] && status="Fail"
  log_finding "$id" "$title" "$risk" "$status" "$remediation" "$notes"
}

### Run All Automated Checks ###
check_log_config_module
check_webdav_module_disabled
check_status_module_disabled
check_default_html_removed
check_tls_versions
check_apache_files_owned_by_root

# === Display Banner While Executing ===
echo "==============================================="
echo "         CIS Benchmark Check for Apache         "
echo "               Developed by: Astra              "
echo "==============================================="

echo "Running audit checks..."

### Generate HTML Report ###
passed=$(grep -c '|Pass|' "$TMP_RESULT")
failed=$(grep -c '|Fail|' "$TMP_RESULT")
total=$((passed + failed))

cat <<EOF > "$HTML_REPORT"
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>CIS Apache Audit Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 20px;
    }
    h1.banner {
      background-color: #004466;
      color: white;
      padding: 10px;
      margin-bottom: 0;
      font-size: 24px;
      text-align: center;
    }
    h3.subtitle {
      background-color: #007799;
      color: white;
      padding: 8px;
      margin-top: 0;
      text-align: center;
      font-weight: normal;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      padding: 10px;
      border: 1px solid #ccc;
      text-align: left;
    }
    th {
      background-color: #f0f0f0;
    }
    .pass {
      background-color: #c8f7c5;
    }
    .fail {
      background-color: #f9c0c0;
    }
    canvas {
      display: block;
      margin: 20px auto;
      max-width: 400px;
    }
  </style>
</head>
<body>
  <h1 class="banner">CIS Benchmark Check 4 Apache</h1>
  <h3 class="subtitle">Developed by: Astra</h3>
  <hr>
  <h1>CIS Apache Benchmark Audit Report</h1>
  <p><strong>Date:</strong> $(date)</p>
  <p><strong>Total Checks:</strong> $total | <strong>Pass:</strong> $passed | <strong>Fail:</strong> $failed</p>
  <canvas id="chart"></canvas>
  <table>
    <tr><th>ID</th><th>Title</th><th>Risk</th><th>Status</th><th>Remediation</th><th>Details</th></tr>
EOF

while IFS='|' read -r id title risk status remediation notes; do
  class=$(echo "$status" | tr '[:upper:]' '[:lower:]')
  echo "<tr class='$class'><td>$id</td><td>$title</td><td>$risk</td><td>$status</td><td>$remediation</td><td><pre>$notes</pre></td></tr>" >> "$HTML_REPORT"
done < "$TMP_RESULT"

echo "</table>" >> "$HTML_REPORT"
echo "<h2>Executive Summary</h2>" >> "$HTML_REPORT"
echo "<ul><li>Total Checks: $total</li><li>Pass: $passed</li><li>Fail: $failed</li></ul>" >> "$HTML_REPORT"
echo "<script>" >> "$HTML_REPORT"
echo "  const passed = $passed;" >> "$HTML_REPORT"
echo "  const failed = $failed;" >> "$HTML_REPORT"
echo "  const canvas = document.getElementById('chart');" >> "$HTML_REPORT"
echo "  const ctx = canvas.getContext('2d');" >> "$HTML_REPORT"
echo "  const total = passed + failed;" >> "$HTML_REPORT"
echo "  const passRatio = passed / total;" >> "$HTML_REPORT"
echo "  const failRatio = failed / total;" >> "$HTML_REPORT"
echo "  let startAngle = 0;" >> "$HTML_REPORT"
echo "  const passAngle = 2 * Math.PI * passRatio;" >> "$HTML_REPORT"
echo "  const failAngle = 2 * Math.PI * failRatio;" >> "$HTML_REPORT"
echo "  ctx.beginPath();" >> "$HTML_REPORT"
echo "  ctx.moveTo(200, 100);" >> "$HTML_REPORT"
echo "  ctx.arc(200, 100, 80, startAngle, startAngle + passAngle);" >> "$HTML_REPORT"
echo "  ctx.fillStyle = '#4CAF50';" >> "$HTML_REPORT"
echo "  ctx.fill();" >> "$HTML_REPORT"
echo "  startAngle += passAngle;" >> "$HTML_REPORT"
echo "  ctx.beginPath();" >> "$HTML_REPORT"
echo "  ctx.moveTo(200, 100);" >> "$HTML_REPORT"
echo "  ctx.arc(200, 100, 80, startAngle, startAngle + failAngle);" >> "$HTML_REPORT"
echo "  ctx.fillStyle = '#F44336';" >> "$HTML_REPORT"
echo "  ctx.fill();" >> "$HTML_REPORT"
echo "  ctx.fillStyle = '#000';" >> "$HTML_REPORT"
echo "  ctx.font = '14px Arial';" >> "$HTML_REPORT"
echo "  ctx.fillText('Pass: ' + passed, 20, 190);" >> "$HTML_REPORT"
echo "  ctx.fillText('Fail: ' + failed, 100, 190);" >> "$HTML_REPORT"
echo "</script>" >> "$HTML_REPORT"
echo "</body></html>" >> "$HTML_REPORT"

rm -f "$TMP_RESULT"
echo "✅ Report generated at $HTML_REPORT"
