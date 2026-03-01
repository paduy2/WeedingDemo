# Generate Guest Invitation URLs
# Usage: .\generate-guest-urls.ps1 [-Domain <domain>] [-Output <file>]

param(
    [Parameter(Mandatory=$false)]
    [string]$Domain = "https://duythuongwedding.com",

    [Parameter(Mandatory=$false)]
    [string]$GuestsFile = "terraform\guests.json",

    [Parameter(Mandatory=$false)]
    [string]$Output = "guest-urls.txt"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Wedding Invitation URL Generator" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if guests.json exists
if (-not (Test-Path $GuestsFile)) {
    Write-Host "ERROR: File not found: $GuestsFile" -ForegroundColor Red
    exit 1
}

# Read guests.json
try {
    $guestsData = Get-Content $GuestsFile -Raw | ConvertFrom-Json
}
catch {
    Write-Host "ERROR: Cannot parse JSON file" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if (-not $guestsData.guests) {
    Write-Host "ERROR: No 'guests' array found in JSON" -ForegroundColor Red
    exit 1
}

Write-Host "Domain: $Domain" -ForegroundColor Yellow
Write-Host "Guests file: $GuestsFile" -ForegroundColor Yellow
Write-Host "Total guests: $($guestsData.guests.Count)" -ForegroundColor Yellow
Write-Host ""

# Generate URLs
$urls = @()
$csvData = @()

Write-Host "Generated URLs:" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

foreach ($guest in $guestsData.guests) {
    $url = "$Domain/?guest=$($guest.id)"
    $tableInfo = ""

    if ($guestsData.tables) {
        $table = $guestsData.tables | Where-Object { $_.number -eq $guest.table }
        if ($table -and $table.type) {
            $tableInfo = " ($($table.type))"
        }
    }

    $plusOneText = if ($guest.plusOne) { "✓ +1" } else { "" }

    # Console output
    Write-Host "[$($guest.id)]" -ForegroundColor Cyan -NoNewline
    Write-Host " $($guest.name)" -ForegroundColor White -NoNewline
    Write-Host " | Bàn $($guest.table)$tableInfo" -ForegroundColor Gray -NoNewline
    if ($guest.plusOne) {
        Write-Host " | $plusOneText" -ForegroundColor Green -NoNewline
    }
    Write-Host ""
    Write-Host "    → $url" -ForegroundColor Yellow
    Write-Host ""

    # Store for file output
    $urls += @{
        ID = $guest.id
        Name = $guest.name
        Table = $guest.table
        PlusOne = $guest.plusOne
        URL = $url
    }

    # CSV data
    $csvData += [PSCustomObject]@{
        GuestID = $guest.id
        GuestName = $guest.name
        Table = $guest.table
        PlusOne = if ($guest.plusOne) { "Yes" } else { "No" }
        URL = $url
    }
}

# Write to text file
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""
Write-Host "Saving to file: $Output" -ForegroundColor Cyan

$outputContent = @"
============================================
Wedding Invitation URLs
Domain: $Domain
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Total Guests: $($guestsData.guests.Count)
============================================

"@

foreach ($urlObj in $urls) {
    $plusOneText = if ($urlObj.PlusOne) { " [+1 person]" } else { "" }
    $outputContent += @"
[$($urlObj.ID)] $($urlObj.Name)
Table: $($urlObj.Table)$plusOneText
URL: $($urlObj.URL)

"@
}

$outputContent += @"

============================================
Usage:
1. Copy individual URLs and send to guests
2. Or use CSV file for mail merge
============================================
"@

$outputContent | Out-File -FilePath $Output -Encoding UTF8
Write-Host "✓ Saved text file: $Output" -ForegroundColor Green

# Write to CSV
$csvFile = $Output -replace '\.txt$', '.csv'
$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
Write-Host "✓ Saved CSV file: $csvFile" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$totalGuests = $guestsData.guests.Count
$guestsWithPlusOne = ($guestsData.guests | Where-Object { $_.plusOne }).Count
$confirmedGuests = ($guestsData.guests | Where-Object { $_.confirmed }).Count

Write-Host "Total Guests:         $totalGuests" -ForegroundColor White
Write-Host "With +1 Person:       $guestsWithPlusOne" -ForegroundColor White
Write-Host "Confirmed:            $confirmedGuests" -ForegroundColor Green
Write-Host ""

if ($guestsData.tables) {
    Write-Host "Tables:" -ForegroundColor Yellow
    foreach ($table in $guestsData.tables) {
        $guestsAtTable = ($guestsData.guests | Where-Object { $_.table -eq $table.number }).Count
        Write-Host "  Bàn $($table.number) ($($table.type)): $guestsAtTable guests / $($table.capacity) capacity" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Review generated URLs in: $Output" -ForegroundColor White
Write-Host "2. Test a few URLs in browser" -ForegroundColor White
Write-Host "3. Send personalized links to guests via:" -ForegroundColor White
Write-Host "   • Email (mail merge with CSV)" -ForegroundColor Gray
Write-Host "   • SMS" -ForegroundColor Gray
Write-Host "   • Zalo/Messenger" -ForegroundColor Gray
Write-Host ""
Write-Host "✓ Done!" -ForegroundColor Green
Write-Host ""
