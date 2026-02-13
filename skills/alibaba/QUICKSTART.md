# Quick Start Guide

Get up and running in 5 minutes!

## 1. Install Dependencies (2 min)

```bash
cd /home/linus/.openclaw/workspace/devops/skills/alibaba/epost_ch

# Install Python packages
pip install -r requirements.txt

# Install Alibaba scraper
pipx install aba-cli-scrapper

# Install browser for scraping
playwright install chromium
```

## 2. Get API Key (1 min)

Sign up for a proxy service (required to avoid blocking):

**Syphoon** (Recommended - easier setup):
1. Visit: https://account.syphoon.com
2. Sign up for free trial
3. Copy your API key

**OR BrightData**:
1. Visit: https://brightdata.com
2. Sign up and get Scraping Browser API key
3. Copy your API key

## 3. Configure (30 sec)

```bash
# Set your API key
./alibaba-search configure --provider syphoon --api-key YOUR_API_KEY_HERE
```

## 4. First Search! (1 min)

```bash
# Search for products
./alibaba-search search "usb cables" --pages 5

# View results
./alibaba-search list
```

## 5. Check Your Data (30 sec)

```bash
# Results are saved in:
ls data/

# View CSV export
cat data/usb_cables.csv | head -20
```

## ✅ You're Ready!

### Next Steps:

**Try monitoring:**
```bash
./alibaba-search monitor "led lights" --interval 300
```

**Set up Google Sheets:**
- See README.md "Google Sheets Setup" section
- Sync your data automatically

**Explore examples:**
```bash
cd examples/
./basic_search.sh
```

## Common Commands

```bash
# Search with more pages
./alibaba-search search "product name" --pages 20

# Export to Google Sheets
./alibaba-search search "product name" --pages 10 --sheets

# Monitor every 10 minutes
./alibaba-search monitor "product name" --interval 600

# Get seller info
./alibaba-search seller --product-url "https://www.alibaba.com/product-detail/..."

# List all tracked products
./alibaba-search list

# View config
./alibaba-search configure --show
```

## Troubleshooting

**"API key not set"**
```bash
./alibaba-search configure --api-key YOUR_KEY --provider syphoon
```

**"aba-run command not found"**
```bash
pipx install aba-cli-scrapper
```

**Google Sheets not working**
```bash
# Install Google API packages
pip install google-auth google-api-python-client

# Set up credentials (see README.md)
```

## Need Help?

- Read full README.md
- Check SKILL.md for all commands
- Visit: https://github.com/poneoneo/Alibaba-CLI-Scraper

Happy scraping! 🚀
