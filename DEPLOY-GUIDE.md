# 🚀 HƯỚNG DẪN DEPLOY WEDDING INVITATION LÊN AWS

## 📋 CHUẨN BỊ

### 1. Cài đặt công cụ

#### A. AWS CLI
```powershell
# Tải về từ: https://aws.amazon.click/cli/
# Hoặc dùng chocolatey:
choco install awscli

# Kiểm tra cài đặt
aws --version
```

#### B. Terraform
```powershell
# Tải về từ: https://www.terraform.io/downloads
# Hoặc dùng chocolatey:
choco install terraform

# Kiểm tra cài đặt
terraform --version
```

### 2. Tạo AWS Account

1. Truy cập: https://aws.amazon.click
2. Click "Create an AWS Account"
3. Điền thông tin (cần thẻ tín dụng, nhưng sẽ không bị charge nếu dùng Free Tier)
4. Xác thực email và số điện thoại

### 3. Tạo IAM User cho Deployment

```powershell
# Đăng nhập AWS Console → IAM → Users → Create User

Tên user: wedding-deployment
Permissions: Attach policies directly
  ✅ AmazonS3FullAccess
  ✅ CloudFrontFullAccess
  ✅ AmazonRoute53FullAccess
  ✅ AWSCertificateManagerFullAccess

# Tạo Access Key
→ Security credentials tab → Create access key
→ Chọn "Command Line Interface (CLI)"
→ Download .csv file (LƯU KỸ FILE NÀY!)
```

### 4. Cấu hình AWS CLI

```powershell
aws configure

AWS Access Key ID: [Paste từ file .csv]
AWS Secret Access Key: [Paste từ file .csv]
Default region name: ap-southeast-1    # Singapore (gần VN nhất)
Default output format: json
```

Kiểm tra:
```powershell
aws sts get-caller-identity
# Nếu thấy thông tin user → OK!
```

---

## 🌐 BƯỚC 1: MUA & SETUP DOMAIN

### Option A: Mua domain từ Namecheap (Khuyên dùng - rẻ nhất)

1. Truy cập: https://namecheap.click
2. Tìm domain: `duythuongwedding.click`
3. Mua domain (~$3/năm)
4. **CHƯA SETUP NAMESERVERS** - sẽ làm ở bước sau

### Option B: Mua domain từ AWS Route53

```powershell
# Đắt hơn ($15/năm) nhưng tự động setup
aws route53domains register-domain \
  --domain-name duythuongwedding.click \
  --duration-in-years 1
```

---

## 🏗️ BƯỚC 2: TẠO ROUTE53 HOSTED ZONE

```powershell
cd f:\wedding\WeddingInvitation\terraform

# Chạy script setup domain
.\setup-domain.ps1
```

Script sẽ tạo Route53 Hosted Zone và hiển thị 4 nameservers như:
```
ns-1234.awsdns-12.org
ns-5678.awsdns-56.co.uk
ns-910.awsdns-91.click
ns-1112.awsdns-11.net
```

**⚠️ LƯU LẠI 4 NAMESERVERS NÀY!**

---

## 🔗 BƯỚC 3: UPDATE NAMESERVERS Ở DOMAIN REGISTRAR

### Nếu dùng Namecheap:

1. Login Namecheap → Domain List
2. Click "Manage" bên cạnh domain của bạn
3. Tìm phần "NAMESERVERS"
4. Chọn "Custom DNS"
5. Paste 4 nameservers từ bước trên:
   ```
   ns-1234.awsdns-12.org
   ns-5678.awsdns-56.co.uk
   ns-910.awsdns-91.click
   ns-1112.awsdns-11.net
   ```
6. Click "✓" để save

### Kiểm tra DNS propagation:

```powershell
# Chờ 2-10 phút rồi kiểm tra
nslookup -type=NS duythuongwedding.click

# Hoặc dùng online tool:
# https://dnschecker.org
```

**✅ Khi thấy 4 nameservers AWS xuất hiện → OK!**

---

## 📝 BƯỚC 4: CHUẨN BỊ FILES

### A. Cập nhật thông tin domain

Tạo file `production.tfvars`:
```powershell
cd f:\wedding\WeddingInvitation\terraform
Copy-Item terraform.tfvars.example production.tfvars

# Sau đó edit production.tfvars
code production.tfvars
```

Nội dung `production.tfvars`:
```hcl
domain_name = "duythuongwedding.click"    # ← Đổi thành domain của bạn
aws_region  = "ap-southeast-1"            # Singapore
environment = "production"
cloudfront_price_class = "PriceClass_100"  # Rẻ nhất (US, Europe, Asia)

cache_ttl = {
  min     = 0
  default = 300    # 5 phút
  max     = 600    # 10 phút
}
```

### B. Cập nhật danh sách khách mời

Edit `terraform/guests.json`:
```json
{
  "event": {
    "title": "Đám cưới Duy & Thương",
    "date": "2026-03-15",
    "time": "18:00",
    "venue": "Nhà Thờ Đức Bà, TP.HCM"
  },
  "guests": [
    {
      "id": "G001",
      "name": "Nguyễn Văn A",
      "plusOne": false
    },
    {
      "id": "G002",
      "name": "Trần Thị B",
      "plusOne": true
    }
  ]
}
```

### C. Cập nhật CloudFront URL trong index.html

Edit dòng ~885 trong `index.html`:
```javascript
const GUESTS_JSON_URL = 'https://duythuongwedding.click/guests.json';
```

---

## 🚀 BƯỚC 5: DEPLOY INFRASTRUCTURE LÊN AWS

### Khởi tạo Terraform (chỉ làm lần đầu):

```powershell
cd f:\wedding\WeddingInvitation\terraform
.\deploy.ps1 -Command init
```

Output:
```
Terraform has been successfully initialized!
```

### Xem trước những gì sẽ được tạo:

```powershell
.\deploy.ps1 -Command plan -VarFile production.tfvars
```

Terraform sẽ liệt kê:
- ✅ S3 bucket (duythuongwedding.click-data)
- ✅ CloudFront distribution
- ✅ ACM certificate (SSL miễn phí)
- ✅ Route53 records
- ✅ Security policies

### Deploy lên AWS:

```powershell
.\deploy.ps1 -Command apply -VarFile production.tfvars
```

Terraform sẽ hỏi xác nhận:
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes    # ← Gõ "yes" và Enter
```

**⏱️ Chờ khoảng 20-30 phút:**
- ACM certificate validation qua DNS: ~5-10 phút
- CloudFront distribution deployment: ~15-20 phút

### Kiểm tra khi hoàn thành:

```powershell
terraform output
```

Output:
```
cloudfront_distribution_id = "E1234ABCD5678"
s3_bucket_name = "duythuongwedding.click-data"
website_url = "https://duythuongwedding.click/guests.json"
```

---

## 📤 BƯỚC 6: UPLOAD WEBSITE LÊN AWS S3 + CLOUDFRONT

Dùng script tự động để upload toàn bộ website (index.html + assets):

```powershell
.\upload-to-aws.ps1
```

Output:
```
📦 AWS Account: 820242922303
📦 Bắt đầu upload lên S3...

📦 Uploading index.html...
✅ index.html uploaded
📦 Uploading assets folder...
✅ Assets uploaded

✅ Upload hoàn tất!

📦 Invalidating CloudFront cache...
✅ Cache invalidation created: I2XYZ123ABC
📦 Chờ 1-2 phút để cache được clear hoàn toàn

✅ 🎉 Xong! Website đã được update tại:
   https://www.duythuongwedding.click
```

### Các options:

**Upload + clear cache ngay (khuyên dùng):**
```powershell
.\upload-to-aws.ps1
```

**Upload nhưng không clear cache (tiết kiệm invalidation requests):**
```powershell
.\upload-to-aws.ps1 -SkipInvalidation
```

**Clear cache thủ công sau:**
```powershell
aws cloudfront create-invalidation --distribution-id E2A5TAB88RNGN7 --paths "/*"
```

### Kiểm tra:
```powershell
# Test website
https://www.duythuongwedding.click

# Kiểm tra CloudFront distribution status
aws cloudfront get-distribution --id E2A5TAB88RNGN7 --query "Distribution.Status"
```

---

## 🎯 BƯỚC 7: TEST WEBSITE

### Test personalized URLs:

```
https://duythuongwedding.click/?guest=G001
https://duythuongwedding.click/?guest=G002
```

Mỗi URL sẽ hiển thị tên khách mời khác nhau!

### Generate URLs cho tất cả khách:

```powershell
cd f:\wedding\WeddingInvitation
.\generate-guest-urls.ps1 -Domain "https://duythuongwedding.click"
```

Output:
```
[G001] Nguyễn Văn A
    → https://duythuongwedding.click/?guest=G001

[G002] Trần Thị B
    → https://duythuongwedding.click/?guest=G002
```

Copy URLs này và gửi cho từng khách mời!

---

## 💰 CHI PHÍ DỰ KIẾN

| Dịch vụ | Chi phí |
|---------|---------|
| Domain .click (Namecheap) | $3/năm |
| Route53 Hosted Zone | $0.50/tháng = $6/năm |
| S3 Storage | ~$0.01/tháng |
| CloudFront | FREE tier (1TB/tháng) |
| ACM Certificate | FREE |
| Website Hosting (Netlify) | FREE |
| **TỔNG** | **~$9/năm** |

---

## 🔄 CẬP NHẬT WEBSITE SAU NÀY

Khi cần update nội dung website, sửa index.html hoặc assets:

```powershell
# 1. Sửa file index.html hoặc assets/
code index.html

# 2. Upload lên AWS (tự động clear cache)
.\upload-to-aws.ps1
```

Hoặc nếu chỉ muốn upload không clear cache:
```powershell
.\upload-to-aws.ps1 -SkipInvalidation
```

---

## 🆘 TROUBLESHOOTING

### Lỗi: "AccessDenied" khi chạy Terraform

**Nguyên nhân**: IAM user thiếu quyền

**Fix**:
```powershell
# Kiểm tra IAM policies
aws iam list-attached-user-policies --user-name wedding-deployment
```

### Lỗi: DNS không resolve

**Nguyên nhân**: Nameservers chưa propagate

**Fix**:
```powershell
# Chờ 2-48h và kiểm tra:
nslookup duythuongwedding.click

# Xóa DNS cache local:
ipconfig /flushdns
```

### Lỗi: 403 Forbidden khi truy cập guests.json

**Nguyên nhân**: CloudFront chưa deploy xong

**Fix**: Chờ 20-30 phút sau khi `terraform apply`

### Lỗi: Certificate validation timeout

**Nguyên nhân**: DNS records chưa được add

**Fix**:
```powershell
# Kiểm tra Route53 records
aws route53 list-resource-record-sets --hosted-zone-id Z123456789
```

---

## 🎉 HOÀN TẤT!

Bây giờ bạn có:
- ✅ Website đám cưới với HTTPS
- ✅ Domain tùy chỉnh (duythuongwedding.click)
- ✅ Personalized URLs cho từng khách
- ✅ Secure infrastructure trên AWS
- ✅ Chi phí chỉ ~$9/năm

---

## 📞 HỖ TRỢ

Nếu gặp vấn đề, kiểm tra:
1. AWS Console → CloudFront → Distributions
2. AWS Console → S3 → Buckets
3. AWS Console → Route53 → Hosted zones
4. Terraform logs: `terraform show`

Good luck! 🎊💒
