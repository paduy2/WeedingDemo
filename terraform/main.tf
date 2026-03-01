terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider cho resources chính (S3, CloudFront)
provider "aws" {
  region = var.aws_region
}

# Provider riêng cho ACM certificate (phải ở us-east-1 cho CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# REMOVED: S3 bucket and CloudFront for API are no longer needed
# Guest data is now embedded directly in index.html for security

# resource "aws_s3_bucket" "wedding_data" {
#   bucket = "${var.domain_name}-data"
#   tags = {
#     Name        = "Wedding Guest Data"
#     Environment = var.environment
#     Project     = "DuyThuongWedding"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "wedding_data" {
#   bucket = aws_s3_bucket.wedding_data.id
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_cors_configuration" "wedding_data" {
#   bucket = aws_s3_bucket.wedding_data.id
#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET", "HEAD"]
#     allowed_origins = ["https://${var.domain_name}"]
#     expose_headers  = ["ETag"]
#     max_age_seconds = 3000
#   }
# }

# resource "aws_cloudfront_origin_access_control" "wedding_data" {
#   name                              = "${var.domain_name}-oac"
#   description                       = "OAC for wedding data bucket"
#   origin_access_control_origin_type = "s3"
#   signing_behavior                  = "always"
#   signing_protocol                  = "sigv4"
# }

# ACM Certificate cho HTTPS - FREE
# Covers both apex domain and www subdomain
resource "aws_acm_certificate" "wedding" {
  provider          = aws.us_east_1  # PHẢI ở us-east-1 cho CloudFront
  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "Wedding SSL Certificate"
    Project = "DuyThuongWedding"
  }
}

# Route53 Hosted Zone - domain chính
data "aws_route53_zone" "wedding" {
  name         = var.domain_name
  private_zone = false
}

# DNS validation record cho ACM certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.wedding.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.wedding.zone_id
}

# Chờ certificate được validate
resource "aws_acm_certificate_validation" "wedding" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.wedding.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# REMOVED: CloudFront distribution for API no longer needed
# resource "aws_cloudfront_distribution" "wedding_data" {
#   enabled             = true
#   is_ipv6_enabled     = true
#   comment             = "Wedding guest data distribution"
#   default_root_object = ""
#   aliases             = [var.domain_name]
#   price_class         = var.cloudfront_price_class
#   origin {
#     domain_name              = aws_s3_bucket.wedding_data.bucket_regional_domain_name
#     origin_id                = "S3-${aws_s3_bucket.wedding_data.id}"
#     origin_access_control_id = aws_cloudfront_origin_access_control.wedding_data.id
#   }
#   default_cache_behavior {
#     allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#     cached_methods   = ["GET", "HEAD"]
#     target_origin_id = "S3-${aws_s3_bucket.wedding_data.id}"
#     forwarded_values {
#       query_string = false
#       cookies {
#         forward = "none"
#       }
#     }
#     viewer_protocol_policy = "redirect-to-https"
#     min_ttl                = var.cache_ttl.min
#     default_ttl            = var.cache_ttl.default
#     max_ttl                = var.cache_ttl.max
#     compress               = true
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }
#   viewer_certificate {
#     acm_certificate_arn      = aws_acm_certificate.wedding.arn
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1.2_2021"
#   }
#   tags = {
#     Name        = "Wedding Data Distribution"
#     Environment = var.environment
#     Project     = "DuyThuongWedding"
#   }
#   depends_on = [aws_acm_certificate_validation.wedding]
# }

# resource "aws_s3_bucket_policy" "wedding_data" {
#   bucket = aws_s3_bucket.wedding_data.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowCloudFrontOAC"
#         Effect = "Allow"
#         Principal = {
#           Service = "cloudfront.amazonaws.com"
#         }
#         Action   = "s3:GetObject"
#         Resource = "${aws_s3_bucket.wedding_data.arn}/*"
#         Condition = {
#           StringEquals = {
#             "AWS:SourceArn" = aws_cloudfront_distribution.wedding_data.arn
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_route53_record" "wedding_cloudfront" {
#   zone_id = data.aws_route53_zone.wedding.zone_id
#   name    = var.domain_name
#   type    = "A"
#   alias {
#     name                   = aws_cloudfront_distribution.wedding_data.domain_name
#     zone_id                = aws_cloudfront_distribution.wedding_data.hosted_zone_id
#     evaluate_target_health = false
#   }
# }
