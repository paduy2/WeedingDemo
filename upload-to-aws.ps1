# Upload wedding website to AWS S3
# Usage: .\upload-to-aws.ps1

$BUCKET_NAME = "duythuongwedding.click"
$REGION = "ap-southeast-1"

Write-Host "Uploading to S3..." -ForegroundColor Yellow

# Upload index.html
aws s3 cp index.html "s3://$BUCKET_NAME/index.html" --region $REGION --content-type "text/html; charset=utf-8" --cache-control "max-age=300"

# Upload assets folder
aws s3 sync assets/ "s3://$BUCKET_NAME/assets/" --region $REGION --cache-control "max-age=31536000" --delete

Write-Host "Done! Website: https://www.duythuongwedding.click" -ForegroundColor Green
