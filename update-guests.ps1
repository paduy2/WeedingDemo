# Update Guest Data Script
# This script encodes guests.json to Base64 and updates index.html

$ErrorActionPreference = "Stop"

Write-Host "=== Wedding Guest Data Update Script ===" -ForegroundColor Cyan
Write-Host ""

# Paths
$guestsJsonPath = "terraform/guests.json"
$indexHtmlPath = "index.html"

# Check if files exist
if (-not (Test-Path $guestsJsonPath)) {
    Write-Host "ERROR: $guestsJsonPath not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $indexHtmlPath)) {
    Write-Host "ERROR: $indexHtmlPath not found!" -ForegroundColor Red
    exit 1
}

# Read and encode guests.json
Write-Host "Reading $guestsJsonPath..." -ForegroundColor Yellow
$guestsJson = Get-Content $guestsJsonPath -Raw -Encoding UTF8
$bytes = [System.Text.Encoding]::UTF8.GetBytes($guestsJson)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "Encoded guest data to Base64 ($($base64.Length) characters)" -ForegroundColor Green

# Read index.html
Write-Host "Reading $indexHtmlPath..." -ForegroundColor Yellow
$indexHtml = Get-Content $indexHtmlPath -Raw -Encoding UTF8

# Update the ENCODED_GUEST_DATA line
$pattern = "const ENCODED_GUEST_DATA = '[^']*';"
$replacement = "const ENCODED_GUEST_DATA = '$base64';"

if ($indexHtml -match $pattern) {
    $indexHtml = $indexHtml -replace $pattern, $replacement
    Set-Content $indexHtmlPath -Value $indexHtml -Encoding UTF8 -NoNewline
    Write-Host "Successfully updated $indexHtmlPath!" -ForegroundColor Green
} else {
    Write-Host "ERROR: Could not find ENCODED_GUEST_DATA in $indexHtmlPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Update Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test locally by opening index.html in browser"
Write-Host "2. Upload to S3: aws s3 cp index.html s3://duythuongwedding.click/"
Write-Host "3. Invalidate cache: aws cloudfront create-invalidation --distribution-id E2A5TAB88RNGN7 --paths '/*'"
Write-Host ""
