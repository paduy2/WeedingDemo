# Wedding Invitation - Terraform Infrastructure

AWS infrastructure for secure wedding invitation website with S3 + CloudFront + HTTPS.

## Architecture

```
User Browser → HTTPS → duythuongwedding.click (CloudFront)
                            ↓ (OAC - Origin Access Control)
                        S3 Private Bucket
                            ↓
                        guests.json
```

## Security

- ✅ S3 bucket completely private (no public access)
- ✅ CloudFront with Origin Access Control (OAC)
- ✅ HTTPS enforced with free ACM certificate
- ✅ No AWS credentials in frontend code

## Cost

| Service | Cost |
|---------|------|
| ACM Certificate | FREE |
| CloudFront | FREE tier (1TB/month) |
| S3 | FREE tier (5GB + 20k requests) |
| Route53 Hosted Zone | $0.50/month |
| **Total** | **~$0.50/month** |

## Prerequisites

1. **AWS CLI** configured:
   ```bash
   aws configure
   ```

2. **Terraform** >= 1.0 installed

3. **Domain** with Route53 hosted zone:
   ```powershell
   # Create hosted zone
   .\setup-domain.ps1

   # Update nameservers at your domain registrar (Namecheap/GoDaddy)
   # See main README.md for detailed instructions
   ```

## Quick Deploy

### 1. Initialize Terraform
```powershell
cd terraform
.\deploy.ps1 -Command init
```

### 2. Deploy Infrastructure
```powershell
# Review changes
.\deploy.ps1 -Command plan -VarFile production.tfvars

# Deploy (takes ~20-30 minutes)
.\deploy.ps1 -Command apply -VarFile production.tfvars
```

This creates:
- S3 bucket: `duythuongwedding.click-data`
- CloudFront distribution with OAC
- ACM certificate (auto-validated via DNS)
- Route53 A record pointing to CloudFront

### 3. Upload Guest Data
```powershell
.\deploy.ps1 -Command upload
```

### 4. Test
```bash
curl https://duythuongwedding.click/guests.json
```

## Configuration

Edit `production.tfvars`:
```hcl
domain_name = "duythuongwedding.click"
aws_region = "ap-southeast-1"
environment = "production"
cloudfront_price_class = "PriceClass_100"
cache_ttl = {
  min     = 0
  default = 300  # 5 minutes
  max     = 600  # 10 minutes
}
```

## Deploy Commands

All commands use the `deploy.ps1` script:

```powershell
# Initialize
.\deploy.ps1 -Command init

# Plan changes
.\deploy.ps1 -Command plan -VarFile production.tfvars

# Apply changes
.\deploy.ps1 -Command apply -VarFile production.tfvars

# Upload guests.json
.\deploy.ps1 -Command upload

# Clear CloudFront cache
.\deploy.ps1 -Command invalidate

# Destroy everything
.\deploy.ps1 -Command destroy -VarFile production.tfvars
```

## Update Guest List

```powershell
# 1. Edit guests.json
code guests.json

# 2. Upload to S3
.\deploy.ps1 -Command upload

# 3. Clear cache (optional - see changes immediately)
.\deploy.ps1 -Command invalidate
```

**Note**: Default cache is 5 minutes. Without invalidation, changes appear after 5 minutes.

## Outputs

After deployment, view outputs:
```bash
terraform output
```

Available outputs:
- `s3_bucket_name` - S3 bucket name
- `cloudfront_distribution_id` - CloudFront distribution ID
- `website_url` - CloudFront URL for guests.json
- `upload_command` - Command to upload files

## Troubleshooting

### CloudFront returns 403
- Wait 20-30 minutes for distribution to deploy
- Verify file uploaded: `aws s3 ls s3://duythuongwedding.click-data/`

### DNS not resolving
```bash
# Check DNS
nslookup duythuongwedding.click

# Check Route53 records
aws route53 list-hosted-zones
```

### ACM certificate not validated
- Ensure DNS propagated before running terraform apply
- Check certificate status: `aws acm list-certificates --region us-east-1`

## Security Best Practices

### DO NOT:
- ❌ Enable public access on S3 bucket
- ❌ Hardcode AWS credentials in code
- ❌ Commit `*.tfstate` to git
- ❌ Commit `*.tfvars` to git

### DO:
- ✅ Keep S3 private with OAC
- ✅ Use IAM user with minimal permissions
- ✅ Review `.gitignore` protections

## Files Structure

```
terraform/
├── main.tf                      # Infrastructure definitions
├── variables.tf                 # Variable definitions (no defaults)
├── outputs.tf                   # Output definitions
├── production.tfvars            # Production config (gitignored)
├── terraform.tfvars.example     # Template (committed)
├── guests.json                  # Guest data (gitignored)
├── deploy.ps1                   # Deployment script
└── setup-domain.ps1             # Route53 setup helper
```

### Committed to git:
- ✅ `main.tf`, `variables.tf`, `outputs.tf`
- ✅ `terraform.tfvars.example`
- ✅ `deploy.ps1`, `setup-domain.ps1`
- ✅ `README.md`

### NOT committed (gitignored):
- ❌ `production.tfvars` (contains domain config)
- ❌ `*.tfstate` (Terraform state)
- ❌ `guests.json` (sensitive guest data)

## License

MIT
