# Deploy script for Wedding Invitation Infrastructure (PowerShell version)
# Usage: .\deploy.ps1 -Command <command> [-VarFile <file>]

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('init', 'plan', 'apply', 'upload', 'invalidate', 'destroy', 'help')]
    [string]$Command,

    [Parameter(Mandatory=$false)]
    [string]$VarFile = "production.tfvars"
)

function Write-Success {
    param([string]$Message)
    Write-Host "OK $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "ERROR $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "INFO $Message" -ForegroundColor Yellow
}

function Check-Requirements {
    Write-Info "Checking requirements..."

    # Check Terraform
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "Terraform not installed. Please install from: https://www.terraform.io/downloads"
        exit 1
    }
    $tfVersion = (terraform version -json | ConvertFrom-Json).terraform_version
    Write-Success "Terraform: $tfVersion"

    # Check AWS CLI
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "AWS CLI not installed. Please install from: https://aws.amazon.com/cli/"
        exit 1
    }
    $awsVersion = (aws --version).Split()[0]
    Write-Success "AWS CLI: $awsVersion"

    # Check AWS credentials
    try {
        $account = aws sts get-caller-identity --query Account --output text 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw
        }
        Write-Success "AWS Account: $account"
    }
    catch {
        Write-Error-Custom "AWS credentials not configured. Run: aws configure"
        exit 1
    }
}

function Terraform-Init {
    Write-Info "Initializing Terraform..."
    terraform init
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Terraform initialized successfully"
    }
}

function Terraform-Plan {
    Write-Info "Planning infrastructure changes..."
    Write-Info "Using var file: $VarFile"

    if (Test-Path $VarFile) {
        terraform plan -var-file="$VarFile"
    }
    else {
        Write-Info "File $VarFile not found, using terraform.tfvars if exists"
        terraform plan
    }
}

function Terraform-Apply {
    Write-Info "Deploying infrastructure..."
    Write-Info "Using var file: $VarFile"
    Write-Info "This will take approximately 20-30 minutes (ACM validation + CloudFront propagation)"

    if (Test-Path $VarFile) {
        terraform apply -var-file="$VarFile"
    }
    else {
        Write-Info "File $VarFile not found, using terraform.tfvars if exists"
        terraform apply
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Deployment successful!"
        Write-Host ""
        Write-Info "Next steps:"
        Write-Host "1. Upload guests.json: .\deploy.ps1 -Command upload"
        Write-Host "2. Check URL: $(terraform output -raw website_url)"
        Write-Host ""
        Write-Info "Note: CloudFront may take additional 5-10 minutes to be fully active"
    }
    else {
        Write-Error-Custom "Deployment failed. Check errors above."
        exit 1
    }
}

function Upload-Guests {
    if (-not (Test-Path "guests.json")) {
        Write-Error-Custom "File guests.json not found"
        exit 1
    }

    $bucketName = terraform output -raw s3_bucket_name 2>$null

    if ([string]::IsNullOrEmpty($bucketName)) {
        Write-Error-Custom "Infrastructure not deployed yet. Run: .\deploy.ps1 -Command apply"
        exit 1
    }

    Write-Info "Uploading guests.json to S3..."
    aws s3 cp guests.json "s3://$bucketName/guests.json" `
        --content-type "application/json" `
        --metadata-directive REPLACE

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Upload successful!"

        $websiteUrl = terraform output -raw website_url 2>$null
        Write-Host ""
        Write-Info "Access URL: $websiteUrl"
        Write-Info "Wait 5 minutes for cache expiry or run: .\deploy.ps1 -Command invalidate"
    }
}

function Invalidate-Cache {
    $distributionId = terraform output -raw cloudfront_distribution_id 2>$null

    if ([string]::IsNullOrEmpty($distributionId)) {
        Write-Error-Custom "Infrastructure not deployed yet"
        exit 1
    }

    Write-Info "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation `
        --distribution-id "$distributionId" `
        --paths "/guests.json"

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Cache invalidation created. Wait 1-2 minutes to complete."
    }
}

function Terraform-Destroy {
    Write-Info "Destroying all infrastructure..."
    Write-Info "Using var file: $VarFile"

    # Delete S3 files first
    $bucketName = terraform output -raw s3_bucket_name 2>$null
    if (-not [string]::IsNullOrEmpty($bucketName)) {
        Write-Info "Deleting files in S3 bucket..."
        aws s3 rm "s3://$bucketName/" --recursive 2>$null
    }

    if (Test-Path $VarFile) {
        terraform destroy -var-file="$VarFile"
    }
    else {
        Write-Info "File $VarFile not found, using terraform.tfvars if exists"
        terraform destroy
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Success "All infrastructure destroyed"
    }
}

function Show-Help {
    Write-Host "Wedding Invitation - Deploy Script"
    Write-Host ""
    Write-Host "Usage: .\deploy.ps1 -Command <command> [-VarFile <file>]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  init        - Initialize Terraform"
    Write-Host "  plan        - Preview infrastructure changes"
    Write-Host "  apply       - Deploy infrastructure (takes ~20-30 minutes)"
    Write-Host "  upload      - Upload guests.json to S3"
    Write-Host "  invalidate  - Clear CloudFront cache (see changes immediately)"
    Write-Host "  destroy     - Destroy all infrastructure"
    Write-Host "  help        - Show this help message"
    Write-Host ""
    Write-Host "Parameters:"
    Write-Host "  -VarFile    - .tfvars file to use (default: production.tfvars)"
    Write-Host ""
    Write-Host "Example deployment from scratch:"
    Write-Host "  .\deploy.ps1 -Command init"
    Write-Host "  .\deploy.ps1 -Command apply"
    Write-Host "  .\deploy.ps1 -Command apply -VarFile staging.tfvars"
    Write-Host "  .\deploy.ps1 -Command upload"
}

# Main execution
switch ($Command) {
    'init' {
        Check-Requirements
        Terraform-Init
    }
    'plan' {
        Check-Requirements
        Terraform-Plan
    }
    'apply' {
        Check-Requirements
        Terraform-Apply
    }
    'upload' {
        Check-Requirements
        Upload-Guests
    }
    'invalidate' {
        Check-Requirements
        Invalidate-Cache
    }
    'destroy' {
        Check-Requirements
        Terraform-Destroy
    }
    'help' {
        Show-Help
    }
}
