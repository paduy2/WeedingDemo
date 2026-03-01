# Setup Route53 Hosted Zone
# Chạy script này TRƯỚC KHI terraform apply

param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "duythuongwedding.click"
)

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Route53 Hosted Zone Setup" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: AWS CLI not found. Please install it first." -ForegroundColor Red
    Write-Host "Download: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $account = aws sts get-caller-identity --query Account --output text 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw
    }
    Write-Host "✓ AWS Account: $account" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: AWS credentials not configured" -ForegroundColor Red
    Write-Host "Run: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Domain: $DomainName" -ForegroundColor Yellow
Write-Host ""

# Check if hosted zone already exists
Write-Host "Checking if hosted zone already exists..." -ForegroundColor Cyan
$existingZone = aws route53 list-hosted-zones-by-name `
    --dns-name "$DomainName." `
    --max-items 1 `
    --query "HostedZones[?Name=='$DomainName.'].Id" `
    --output text 2>$null

if ($existingZone) {
    Write-Host "✓ Hosted zone already exists: $existingZone" -ForegroundColor Green
    $zoneId = $existingZone
}
else {
    # Create hosted zone
    Write-Host "Creating hosted zone for $DomainName..." -ForegroundColor Cyan

    $callerRef = "wedding-$(Get-Date -Format 'yyyyMMddHHmmss')"

    $result = aws route53 create-hosted-zone `
        --name "$DomainName" `
        --caller-reference "$callerRef" `
        --output json 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to create hosted zone" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }

    $zoneId = ($result | ConvertFrom-Json).HostedZone.Id
    Write-Host "✓ Hosted zone created: $zoneId" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Name Servers (NS Records)" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Get name servers
$nsRecords = aws route53 get-hosted-zone `
    --id $zoneId `
    --query "DelegationSet.NameServers" `
    --output text

if ($nsRecords) {
    Write-Host "Copy these 4 Name Servers to your domain registrar:" -ForegroundColor Yellow
    Write-Host ""
    $nsRecords -split '\s+' | ForEach-Object {
        Write-Host "  → $_" -ForegroundColor Green
    }
    Write-Host ""
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. If you DON'T have a domain yet:" -ForegroundColor Yellow
Write-Host "   → Buy domain at Namecheap/GoDaddy/Cloudflare" -ForegroundColor White
Write-Host "   → Recommended: Namecheap (~`$10/year)" -ForegroundColor White
Write-Host "   → URL: https://namecheap.com" -ForegroundColor Cyan
Write-Host ""

Write-Host "2. Update Name Servers at your registrar:" -ForegroundColor Yellow
Write-Host "   → Login to Namecheap/GoDaddy/etc" -ForegroundColor White
Write-Host "   → Find DNS/Nameserver settings" -ForegroundColor White
Write-Host "   → Change to 'Custom DNS'" -ForegroundColor White
Write-Host "   → Paste the 4 NS records above" -ForegroundColor White
Write-Host "   → Save (propagation takes 24-48 hours)" -ForegroundColor White
Write-Host ""

Write-Host "3. Verify DNS propagation:" -ForegroundColor Yellow
Write-Host "   → Run: nslookup -type=NS $DomainName" -ForegroundColor White
Write-Host "   → Or check: https://dnschecker.org" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. After DNS propagates, deploy Terraform:" -ForegroundColor Yellow
Write-Host "   → cd terraform" -ForegroundColor White
Write-Host "   → .\deploy.ps1 -Command apply -VarFile production.tfvars" -ForegroundColor White
Write-Host ""

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Current Status" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Hosted Zone ID: $zoneId" -ForegroundColor Green
Write-Host "Domain Name:    $DomainName" -ForegroundColor Green
Write-Host "AWS Account:    $account" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Setup complete!" -ForegroundColor Green
Write-Host ""
