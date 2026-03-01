# REMOVED: API-related outputs (guest data now embedded in HTML)
# output "s3_bucket_name" {
#   description = "Tên S3 bucket chứa guests.json"
#   value       = aws_s3_bucket.wedding_data.id
# }
# output "s3_bucket_arn" {
#   description = "ARN của S3 bucket"
#   value       = aws_s3_bucket.wedding_data.arn
# }
# output "cloudfront_distribution_id" {
#   description = "CloudFront Distribution ID"
#   value       = aws_cloudfront_distribution.wedding_data.id
# }
# output "cloudfront_domain_name" {
#   description = "CloudFront domain name"
#   value       = aws_cloudfront_distribution.wedding_data.domain_name
# }
# output "website_url" {
#   description = "URL để truy cập guests.json"
#   value       = "https://${var.domain_name}/guests.json"
# }
# output "upload_command" {
#   description = "Lệnh để upload guests.json lên S3"
#   value       = "aws s3 cp guests.json s3://${aws_s3_bucket.wedding_data.id}/guests.json"
# }

output "certificate_arn" {
  description = "ACM Certificate ARN (covers both apex and www subdomain)"
  value       = aws_acm_certificate.wedding.arn
}

output "website_url" {
  description = "Wedding website URL"
  value       = "https://www.${var.domain_name}"
}
