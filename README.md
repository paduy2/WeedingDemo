# 💐 Wedding Invitation Website - Duy & Thương

Elegant, minimalist wedding invitation website with personalized guest invitations and secure AWS infrastructure.

## ✨ Features

- 🎨 **Elegant European Design** - Classic serif fonts (Playfair Display, Cormorant Garamond)
- 💌 **Personalized Invitations** - Unique URLs for each guest with custom greetings
- 📸 **Full-width Hero Image** - Stunning photo showcase
- ✨ **Smooth Animations** - Fade-in effects throughout
- ⏱️ **Countdown Timer** - Live countdown to wedding day
- 📍 **Google Maps Integration** - Easy venue location with "Mở Google Maps" buttons
- 🖼️ **Photo Gallery** - Beautiful image grid with hover effects
- 🎵 **Background Music** - Optional wedding music player
- 📱 **Fully Responsive** - Perfect on all devices
- 🔒 **Secure AWS Infrastructure** - S3 + CloudFront + OAC (no public bucket access)

## 🚀 Quick Start

### 1. Local Testing

**Open directly:**
```bash
# Windows - Double-click or:
start index.html?guest=G001

# Or use browser:
file:///D:/WeddingInvitation/index.html?guest=G001
```

**Or use Live Server (recommended):**
```bash
# VS Code: Install "Live Server" extension
# Right-click index.html > Open with Live Server
# Then navigate to:
http://localhost:5500/index.html?guest=G001
```

### 2. Customize Guest List

Edit `terraform/guests.json`:
```json
{
  "event": {
    "title": "Đám cưới Duy & Thương",
    "date": "2025-12-31",
    "time": "18:00",
    "venue": "Nhà hàng ABC, TP.HCM"
  },
  "guests": [
    {
      "id": "G001",
      "name": "Nguyễn Văn A",
      "table": 1,
      "plusOne": false
    }
  ]
}
```

**Guest URL Format:**
- Default: `https://duythuongwedding.click/` → Shows "Quý khách"
- Personalized: `https://duythuongwedding.click/?guest=G001` → Shows guest's name

### 3. Generate Guest URLs

```powershell
.\generate-guest-urls.ps1 -Domain "https://duythuongwedding.click"
```

Output:
```
[G001] Nguyễn Văn A | Bàn 1
    → https://duythuongwedding.click/?guest=G001
[G002] Trần Thị B | Bàn 1
    → https://duythuongwedding.click/?guest=G002
```

### 4. Setup Images

Place your photos in `assets/images/`:
- `hero.jpg` - Main photo (1920x1080px recommended)
- `gallery-1.jpg` to `gallery-6.jpg` - Gallery photos (800x1000px)

### 5. Setup Music (Optional)

Place your music file in `assets/music/`:
- `wedding-song.mp3` - Background music

## 📁 Project Structure

```
WeddingInvitation/
├── index.html                       # Main website (with embedded guest data)
├── generate-guest-urls.ps1          # Generate personalized URLs
├── .gitignore                       # Protects sensitive files
├── assets/
│   ├── images/                     # Wedding photos
│   │   ├── hero.jpg
│   │   └── gallery-*.jpg
│   └── music/                      # Background music
│       └── wedding-song.mp3
└── terraform/                       # AWS Infrastructure (IaC)
    ├── main.tf                     # S3 + CloudFront + ACM + Route53
    ├── variables.tf                # Variable definitions
    ├── production.tfvars           # Production configuration
    ├── terraform.tfvars.example    # Template for variables
    ├── guests.json                 # Production guest data
    ├── deploy.ps1                  # Deployment script
    └── setup-domain.ps1            # Route53 setup helper
```

## 💌 Personalized Guest Invitations

### How It Works

1. **Guest Data**: Store guest info in `terraform/guests.json`
2. **Unique URLs**: Each guest gets a personalized link with `?guest=G001`
3. **Auto-Detection**: Website detects environment (file://, localhost, production)
4. **Personalized Display**: Shows guest's name, table number, and plusOne status

### Guest Display Example

**With plusOne:**
```
Kính mời
Nguyễn Văn A

━━━━━━━━━━━━━━━━━
Số bàn: Bàn 1 (VIP)
Bạn có thể mang theo: 1 người thân

Thời gian: 18:00 - 31/12/2025
Địa điểm: Nhà hàng ABC, TP.HCM
```

**Without plusOne:**
```
Kính mời
Trần Thị B

━━━━━━━━━━━━━━━━━
Số bàn: Bàn 2

Thời gian: 18:00 - 31/12/2025
Địa điểm: Nhà hàng ABC, TP.HCM
```

### Testing Personalization

```bash
# Test different guests
file:///D:/WeddingInvitation/index.html?guest=G001
file:///D:/WeddingInvitation/index.html?guest=G002
file:///D:/WeddingInvitation/index.html?guest=G003

# Test default (no guest parameter)
file:///D:/WeddingInvitation/index.html
```

## 🌐 AWS Deployment

### Prerequisites

1. **Domain**: Buy domain from Namecheap/GoDaddy (~$9/year) or use Route53 ($15/year)
2. **Route53 Hosted Zone**: Create via `terraform/setup-domain.ps1`
3. **AWS CLI**: Configured with credentials
4. **Terraform**: Installed (1.0+)

### Domain Setup

```powershell
cd terraform
.\setup-domain.ps1
```

This will:
- Create Route53 hosted zone for `duythuongwedding.com`
- Display 4 nameservers to update at your domain registrar
- Guide you through DNS setup

**Update nameservers at registrar** (Namecheap/GoDaddy):
1. Login to domain registrar
2. Find "Nameservers" or "DNS Settings"
3. Change to "Custom DNS"
4. Paste the 4 nameservers from setup-domain.ps1
5. Save (DNS propagation: 2-48 hours)

### Infrastructure Deployment

```powershell
cd terraform

# First time - initialize Terraform
.\deploy.ps1 -Command init

# Review what will be created
.\deploy.ps1 -Command plan -VarFile production.tfvars

# Deploy infrastructure
.\deploy.ps1 -Command apply -VarFile production.tfvars
```

This creates:
- ✅ S3 private bucket (`duythuongwedding.click-data`)
- ✅ CloudFront distribution with OAC
- ✅ ACM SSL certificate (FREE, auto-validated via DNS)
- ✅ Route53 A record pointing to CloudFront
- ✅ Secure setup (no public S3 access)

**Deployment time:** ~20-30 minutes (ACM validation + CloudFront deployment)

### Upload Website Files

```powershell
# Upload guests.json to S3
.\deploy.ps1 -Command upload

# Clear CloudFront cache (if updating)
.\deploy.ps1 -Command invalidate
```

### Test Production

```bash
# Test guest data endpoint
curl https://duythuongwedding.click/guests.json

# Test personalized URLs
https://duythuongwedding.click/?guest=G001
https://duythuongwedding.click/?guest=G002
```

## 💰 Cost Breakdown

| Service | Cost | Notes |
|---------|------|-------|
| **Domain** | $9-15/year | Namecheap ($9) or Route53 ($15) |
| **Route53 Hosted Zone** | $0.50/month | $6/year |
| **ACM Certificate** | FREE | Included with AWS |
| **S3 Storage** | ~$0.01/month | 5 guests × 1KB = negligible |
| **CloudFront** | ~$0.01/month | 100 requests/month |
| **Total** | **~$15-21/year** | ≈ $0.50/month + domain |

## 🔐 Security Features

### S3 Bucket Security
- ✅ Completely private (no public access)
- ✅ Block all public ACLs and policies
- ✅ Only CloudFront can access via OAC
- ✅ No AWS credentials in frontend

### CloudFront Security
- ✅ HTTPS enforced (redirect HTTP → HTTPS)
- ✅ Origin Access Control (OAC) - modern security
- ✅ Compression enabled
- ✅ PriceClass_100 (cost-optimized)

### Data Privacy
- ✅ Guest data in private S3
- ✅ No analytics/tracking by default
- ✅ Sensitive files excluded from git (.gitignore)
- ✅ Guest IDs not displayed in UI

## 🎨 Design & Customization

### Typography
- **Playfair Display** - Elegant headings
- **Cormorant Garamond** - Body text
- **Lora** - Accents and labels

### Color Palette
- Primary: `#2c2c2c` (Dark charcoal)
- Secondary: `#8b7355` (Warm brown)
- Accent: `#d4af37` (Gold)
- Background: `#fafaf8` (Soft white)

### Sections (in order)
1. **Hero** - Full-width photo with names & date
2. **Kính mời** - Personalized guest invitation (shows right after hero)
3. **Story** - Love story narrative
4. **Countdown** - Live timer to wedding day
5. **Event Details** - Ceremony & reception info with Google Maps
6. **Gallery** - Photo showcase
7. **Footer** - Final message

### Update Wedding Content

Edit `index.html`:
- Lines ~565-580: Hero section (names, date)
- Lines ~615-650: Love story text
- Lines ~680-720: Event details (venues, times)
- Lines ~820-870: Embedded guest data (for file:// testing)
- Line 814: Production CloudFront URL

## 🔧 Configuration

### Update Wedding Date
```javascript
// In index.html around line 740
const WEDDING_DATE = new Date('2025-12-31T18:00:00').getTime();
```

### Update CloudFront URL
```javascript
// In index.html around line 814
const GUESTS_JSON_URL = 'https://duythuongwedding.click/guests.json';
```

### Update Google Maps
```html
<!-- In Event Details section -->
<a href="https://maps.google.com/?q=Your+Venue+Address" class="map-btn">
    Mở Google Maps
</a>
```

## 📝 Workflow Summary

### Development Workflow
```bash
1. Edit terraform/guests.json          # Update guest list
2. Open index.html?guest=G001          # Test locally
3. Generate URLs for all guests        # .\generate-guest-urls.ps1
4. Send personalized links to guests   # Via email/SMS/Zalo
```

### Production Deployment
```bash
1. Setup domain & Route53              # .\setup-domain.ps1
2. Update nameservers at registrar     # Point to AWS
3. Wait for DNS propagation            # 2-48 hours
4. Deploy infrastructure               # .\deploy.ps1 -Command apply
5. Upload guest data                   # .\deploy.ps1 -Command upload
6. Test production URLs                # https://duythuongwedding.click/?guest=G001
```

### Update Guest List
```bash
1. Edit terraform/guests.json          # Add/remove guests
2. Upload to S3                        # .\deploy.ps1 -Command upload
3. Clear cache                         # .\deploy.ps1 -Command invalidate
4. Generate new URLs if needed         # .\generate-guest-urls.ps1
```

## 🛠️ Tech Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript (no frameworks!)
- **Fonts**: Google Fonts (Playfair Display, Cormorant Garamond, Lora)
- **Infrastructure**: AWS (S3, CloudFront, ACM, Route53)
- **IaC**: Terraform
- **Scripts**: PowerShell (Windows)

## 📱 Browser Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Mobile browsers (iOS/Android)

## 🎯 Performance

- Optimized images (< 500KB each recommended)
- Lazy loading for gallery
- Inline CSS (no external stylesheets)
- No external dependencies
- CloudFront CDN caching (5-10 min TTL)
- Fast page load (< 3s)

## 🆘 Troubleshooting

### Local file:// not showing personalized data
**Solution**: This is expected! The website uses embedded data for file:// protocol. To test with actual guests.json, use Live Server or Python HTTP server.

### Production URL shows "Quý khách" instead of guest name
**Check**:
1. Is guest ID correct? (case-sensitive: G001 vs g001)
2. Is guests.json uploaded to S3?
3. Is CloudFront cache cleared?

```bash
# Verify file in S3
aws s3 ls s3://duythuongwedding.click-data/

# Test direct fetch
curl https://duythuongwedding.click/guests.json

# Clear cache
.\deploy.ps1 -Command invalidate
```

### DNS not propagating
**Check**:
```bash
# Check nameservers
nslookup -type=NS duythuongwedding.click

# Check from different DNS servers
nslookup duythuongwedding.click 8.8.8.8     # Google DNS
nslookup duythuongwedding.click 1.1.1.1     # Cloudflare DNS
```

**Solution**: Wait 2-48 hours for full propagation, or flush local DNS cache:
```bash
ipconfig /flushdns
```

## 📚 Additional Resources

### Domain Registrars
- [Namecheap](https://namecheap.com) - $9/year (recommended)
- [Cloudflare](https://cloudflare.com/products/registrar) - $9/year
- [GoDaddy](https://godaddy.com) - $12/year

### DNS Tools
- [DNS Checker](https://dnschecker.org)
- [What's My DNS](https://whatsmydns.net)

### Wedding Assets
- [Unsplash - Wedding Photos](https://unsplash.com/s/photos/wedding)
- [Pexels - Wedding Photos](https://www.pexels.com/search/wedding/)
- [YouTube Audio Library](https://studio.youtube.com) - Free music

### Design Inspiration
- [Bliss & Bone](https://blissandbone.com) - Design reference

## 📄 Files to Ignore in Git

The `.gitignore` protects:
- Wedding photos (`assets/images/*.jpg`)
- Music files (`assets/music/*.mp3`)
- Guest data (`guests.json`, `guest-urls.txt`)
- Terraform state (`*.tfstate`)
- Terraform variables (`*.tfvars` except example)

## 📄 License

Free to use for your wedding. Customize as you wish!

---

**Made with ❤️ for Duy & Thương**

Design inspired by elegant European wedding aesthetics and [blissandbone.com](https://blissandbone.com).
#   W e e d i n g D e m o  
 