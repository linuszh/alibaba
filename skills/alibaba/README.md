# Alibaba Product Search & Tracking Skill

Comprehensive Alibaba.com product search, tracking, and monitoring with Google Sheets integration.

## 🎯 Features

- ✅ **Product Search**: Search Alibaba.com and scrape detailed product information
- ✅ **Supplier Data**: Collect seller information, ratings, and verification status
- ✅ **Google Sheets Integration**: Automatically sync results to Google Sheets
- ✅ **Real-time Monitoring**: Track products with customizable intervals (default: 5 minutes)
- ✅ **Price Tracking**: Monitor price changes over time
- ⚠️ **Seller Contact**: Extract contact info (direct chat requires manual Alibaba login)

## 📋 Prerequisites

1. **Python 3.11 or higher**
   ```bash
   python3 --version
   ```

2. **Proxy Service API Key**
   
   Alibaba blocks automated scraping, so you need a proxy service:
   
   - **Syphoon** (Recommended): https://account.syphoon.com
   - **BrightData**: https://brightdata.com
   
   Sign up for free trial and get your API key.

3. **Google Sheets Access** (Optional but recommended)
   
   For Google Sheets integration via `gog` skill:
   - Ensure `gog` skill is configured
   - Or manually set up Google Service Account credentials

## 🚀 Installation

### Step 1: Install Dependencies

```bash
cd /home/linus/.openclaw/workspace/devops/skills/alibaba/epost_ch

# Install Python dependencies
pip install -r requirements.txt

# Install aba-cli-scrapper (Alibaba scraper engine)
pipx install aba-cli-scrapper

# Install Playwright browsers (required for scraping)
playwright install chromium
```

### Step 2: Configure API Key

Get your proxy API key from Syphoon or BrightData, then:

```bash
# Configure with Syphoon (recommended)
./alibaba-search configure --provider syphoon --api-key YOUR_API_KEY_HERE

# OR configure with BrightData
./alibaba-search configure --provider brightdata --api-key YOUR_API_KEY_HERE
```

### Step 3: Google Sheets Setup (Optional)

**Option A: Use gog skill** (if already configured)
```bash
# gog skill should already be set up with credentials
# No additional configuration needed
```

**Option B: Manual Google API Setup**

1. Create a Google Cloud Project: https://console.cloud.google.com
2. Enable Google Sheets API
3. Create Service Account and download credentials JSON
4. Save credentials to:
   ```bash
   cp credentials.json ~/.config/gog/credentials.json
   # OR
   cp credentials.json /home/linus/.openclaw/workspace/devops/skills/alibaba/epost_ch/credentials.json
   ```

5. Share your Google Sheets with the service account email

### Step 4: Add to PATH (Optional)

```bash
# Add skill to PATH for easy access
echo 'export PATH="$PATH:/home/linus/.openclaw/workspace/devops/skills/alibaba/epost_ch"' >> ~/.bashrc
source ~/.bashrc

# Now you can use: alibaba-search from anywhere
```

## 📖 Usage

### Basic Search

Search for products and save to database + CSV:

```bash
alibaba-search search "led lights" --pages 10
```

This will:
1. Scrape 10 pages of results from Alibaba
2. Save data to SQLite database
3. Export to CSV
4. Upload to Google Sheets (if configured)

### Search with Custom Options

```bash
# Search 5 pages, skip Google Sheets
alibaba-search search "usb cables" --pages 5 --no-sheets

# Search with custom sheet name
alibaba-search search "phone cases" --pages 8 --sheet-name "Phone Cases Q1 2026"

# Search with custom HTML folder
alibaba-search search "solar panels" --pages 15 --folder solar_results
```

### Monitor Products (Real-time Tracking)

Track products continuously with automatic updates:

```bash
# Monitor every 5 minutes (300 seconds)
alibaba-search monitor "gaming mouse" --interval 300

# Monitor every 10 minutes with Google Sheets sync
alibaba-search monitor "laptop stands" --interval 600 --sheets

# Monitor every hour (3600 seconds)
alibaba-search monitor "office chairs" --interval 3600
```

Press `Ctrl+C` to stop monitoring.

### List Tracked Products

```bash
alibaba-search list
```

Shows all databases with product/supplier counts.

### Export Existing Data to Google Sheets

```bash
alibaba-search export --database data/led_lights.db --sheet-name "LED Products"
```

### Get Seller Contact Information

Extract seller details from a product page:

```bash
alibaba-search seller --product-url "https://www.alibaba.com/product-detail/..."
```

**Note**: Direct chat/messaging requires manual login to Alibaba.com. This command extracts available contact info from the page.

### Configuration Management

```bash
# Show current configuration
alibaba-search configure --show

# Update API key
alibaba-search configure --api-key YOUR_NEW_KEY

# Set Google Sheets spreadsheet ID
alibaba-search configure --spreadsheet-id 1ABC...XYZ

# Change proxy provider
alibaba-search configure --provider syphoon
```

## 📂 Data Structure

### Database Schema

**Products Table:**
- `id`: Product ID
- `name`: Product name
- `min_price`, `max_price`: Price range
- `minimum_to_order`: MOQ (Minimum Order Quantity)
- `supplier_id`: Link to supplier
- `alibaba_guaranteed`: Trade assurance
- `certifications`: Product certifications
- `review_count`, `review_score`: Reviews
- `is_customizable`: Customization available
- And more...

**Suppliers Table:**
- `id`: Supplier ID
- `name`: Company name
- `verification_mode`: Verified/Unverified
- `sopi_level`: Supplier quality level
- `country_name`: Location
- `years_as_gold_supplier`: Years on Alibaba
- `supplier_service_score`: Service rating

### File Locations

```
skills/alibaba/epost_ch/
├── alibaba-search          # Main CLI tool
├── config.json             # Configuration
├── SKILL.md               # Skill documentation
├── README.md              # This file
├── requirements.txt       # Python dependencies
├── lib/                   # Helper libraries
│   ├── sheets_sync.py     # Google Sheets integration
│   └── seller_info.py     # Seller contact extraction
└── data/                  # Generated data (created on first run)
    ├── *.db              # SQLite databases
    ├── *.csv             # Exported CSV files
    └── html_*/           # Raw HTML scrape results
```

## 🔧 Troubleshooting

### "API key not set" Error

```bash
alibaba-search configure --api-key YOUR_API_KEY --provider syphoon
```

### "aba-run: command not found"

```bash
# Install aba-cli-scrapper with pipx
pipx install aba-cli-scrapper

# Or with pip in a virtual environment
python3 -m venv venv
source venv/bin/activate
pip install aba-cli-scrapper
```

### Google Sheets Upload Fails

```bash
# Install Google Sheets dependencies
pip install google-auth google-auth-oauthlib google-api-python-client

# Verify credentials location
ls ~/.config/gog/credentials.json
# OR
ls /home/linus/.openclaw/workspace/devops/skills/alibaba/epost_ch/credentials.json
```

### Scraping Blocked/CAPTCHAs

- Ensure you have a valid proxy API key (Syphoon/BrightData)
- Use async mode (default) instead of sync mode
- Reduce page count if hitting rate limits
- Check proxy service status

### "Playwright not installed"

```bash
playwright install chromium
```

## 🔄 Integration with OpenClaw

### Heartbeat Monitoring

Add to `HEARTBEAT.md` for periodic checks:

```markdown
## Alibaba Price Monitoring

Check tracked products every 6 hours:

```bash
if [ $(date +%H) -eq 6 ] || [ $(date +%H) -eq 12 ] || [ $(date +%H) -eq 18 ]; then
    alibaba-search monitor "led lights" --interval 300 &
fi
```
```

### Discord/Telegram Notifications

For price change alerts, integrate with message skill:

```bash
# When price drops detected
message send discord --channel alerts "🔔 Alibaba: LED lights price dropped to $2.50!"
```

## 📊 Google Sheets Output

The exported spreadsheet includes:

| Column | Description |
|--------|-------------|
| Product Name | Full product title |
| Min Price | Minimum price |
| Max Price | Maximum price |
| Supplier Name | Company name |
| Country | Supplier location |
| Verification | Verified/Unverified |
| MOQ | Minimum order quantity |
| Reviews | Review count and score |
| Years | Years as supplier |
| And more... | 20+ fields total |

## 🚨 Limitations

### Seller Contact/Chat

**What Works:**
- Extract seller name, profile link
- Get verification status
- Pull contact page URL
- Find WhatsApp/WeChat if publicly listed

**What Doesn't Work:**
- Direct automated messaging (requires Alibaba login)
- Trade Messenger chat automation
- Inquiry form submission

**Workaround**: Use the seller contact info to manually reach out via:
1. Login to Alibaba.com
2. Visit product page
3. Click "Contact Supplier"
4. Use Trade Messenger or inquiry form

### Rate Limiting

Alibaba actively blocks automated scraping:
- **Solution**: Use proxy service (Syphoon/BrightData) with valid API key
- Respect rate limits (10-20 pages per request max recommended)
- Use async mode to reduce blocking

## 🛠️ Development

### Add Custom Features

Edit `alibaba-search` to add new commands:

```python
@cli.command()
def my_command():
    """My custom command"""
    pass
```

### Extend Google Sheets Integration

Edit `lib/sheets_sync.py` to customize formatting or add charts.

### Add Notifications

Integrate with OpenClaw message skill in monitoring loop.

## 📝 Examples

### Example 1: Daily Product Research

```bash
# Search for trending products
alibaba-search search "smart home devices 2026" --pages 20 --sheet-name "Smart Home Research"
```

### Example 2: Competitive Price Monitoring

```bash
# Monitor competitor products every 5 minutes
alibaba-search monitor "phone charger USB-C" --interval 300
```

### Example 3: Bulk Supplier Research

```bash
# Search multiple categories
for product in "led lights" "solar panels" "usb cables"; do
    alibaba-search search "$product" --pages 15
    sleep 60  # Wait 1 minute between searches
done
```

### Example 4: Export All Data to Single Sheet

```bash
# Create combined view
alibaba-search export --database data/led_lights.db --sheet-name "Master Product List"
alibaba-search export --database data/usb_cables.db --sheet-name "Master Product List"
```

## 🤝 Contributing

To improve this skill:

1. Fork the repository
2. Make changes in `skills/alibaba/epost_ch/`
3. Test thoroughly
4. Submit pull request

## 📄 License

This skill uses:
- `aba-cli-scrapper` (GNU GPL v3)
- Python packages (various licenses)

See individual package licenses for details.

## 🆘 Support

Issues or questions?

1. Check troubleshooting section above
2. Review `SKILL.md` for command reference
3. Check aba-cli-scrapper docs: https://github.com/poneoneo/Alibaba-CLI-Scraper
4. Open an issue on GitHub

## 🎉 Quick Start Summary

```bash
# 1. Install
pip install -r requirements.txt
pipx install aba-cli-scrapper
playwright install chromium

# 2. Configure
./alibaba-search configure --provider syphoon --api-key YOUR_KEY

# 3. Search!
./alibaba-search search "your product" --pages 10

# 4. Monitor
./alibaba-search monitor "your product" --interval 300
```

Happy product hunting! 🚀
