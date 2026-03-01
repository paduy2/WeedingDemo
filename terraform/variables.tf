variable "aws_region" {
  description = "AWS region cho S3 bucket (gần VN nhất: ap-southeast-1 - Singapore)"
  type        = string
}

variable "domain_name" {
  description = "Domain name cho wedding website"
  type        = string
}

variable "environment" {
  description = "Môi trường deploy (production, staging, development)"
  type        = string
  default     = "production"
}

variable "enable_versioning" {
  description = "Bật versioning cho S3 bucket (để rollback nếu cần)"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront price class (PriceClass_100: US/Europe/Asia rẻ nhất, PriceClass_All: toàn cầu)"
  type        = string
  default     = "PriceClass_100"
}

variable "cache_ttl" {
  description = "CloudFront cache TTL (giây) - thời gian cache guests.json"
  type = object({
    min     = number
    default = number
    max     = number
  })
  default = {
    min     = 0
    default = 300  # 5 phút
    max     = 600  # 10 phút
  }
}
