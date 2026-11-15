#!/usr/bin/env bash
# Generates an HTML server status report to /var/www/html/viikko3/index.html
set -euo pipefail

OUTPUT_DIR="/var/www/html/viikko3"
OUTPUT_FILE="$OUTPUT_DIR/index.html"
REPO_URL="https://github.com/xDeeZy666/la-viikko3"

# Prints OK or WARNING depending on the disk usage percentage given as argument
disk_status() {
    local usage="$1"
    if [ "$usage" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

# Test mode for the status logic, e.g. ./status.sh --test 90
if [ "${1:-}" = "--test" ]; then
    disk_status "$2"
    exit 0
fi

# Collect the information with command substitution and pipes
GENERATED=$(date '+%Y-%m-%d %H:%M:%S %Z (UTC%:z)')
UPTIME=$(uptime -p)
DISK_USAGE=$(df / --output=pcent | tail -n 1 | tr -dc '0-9')
DISK_STATUS=$(disk_status "$DISK_USAGE")
RAM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
RAM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')

if [ "$DISK_STATUS" = "OK" ]; then
    STATUS_COLOR="#4caf50"
else
    STATUS_COLOR="#ff9800"
fi

# Write to a temporary file first, then move it in place, so a visitor
# never sees a half-written page
TMP_FILE=$(mktemp "$OUTPUT_DIR/.report.XXXXXX")

cat > "$TMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>xDeeZy's Server Status – Week 3</title>
  <style>
    body { max-width: 800px; margin: 40px auto; padding: 0 20px; font-family: sans-serif;
           line-height: 1.6; background: #0d0d0d; color: #e6e6e6; }
    h1, h2 { color: #e53935; }
    h1 { border-bottom: 2px solid #e53935; }
    a { color: #ff8a80; }
    table { border-collapse: collapse; width: 100%; }
    td { padding: 8px 12px; border-bottom: 1px solid #333; }
    td:first-child { color: #aaa; width: 45%; }
    .status { font-weight: bold; color: $STATUS_COLOR; }
  </style>
</head>
<body>
  <h1>xDeeZy's Server Status – Week 3</h1>
  <p>This report is generated automatically every minute by a Bash script.</p>
  <table>
    <tr><td>Report generated</td><td>$GENERATED</td></tr>
    <tr><td>Uptime</td><td>$UPTIME</td></tr>
    <tr><td>Disk usage (/)</td><td>$DISK_USAGE %</td></tr>
    <tr><td>Disk space status</td><td class="status">$DISK_STATUS</td></tr>
    <tr><td>RAM total</td><td>$RAM_TOTAL MiB</td></tr>
    <tr><td>RAM available</td><td>$RAM_AVAILABLE MiB</td></tr>
  </table>
  <p>
    <a href="docs.html">Documentation</a> ·
    <a href="$REPO_URL">Source code on GitHub</a> ·
    <a href="/">Week 1</a> ·
    <a href="/viikko2/">Week 2</a>
  </p>
</body>
</html>
EOF

# mktemp creates the file readable only by its owner; Nginx needs read access
chmod 644 "$TMP_FILE"
mv "$TMP_FILE" "$OUTPUT_FILE"
