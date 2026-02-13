# Alibaba Product Search & Tracking Skill

## Overview

This skill provides comprehensive Alibaba.com product search, tracking, and data management capabilities with Google Sheets integration.

## Features

- **Product Search**: Search Alibaba.com for products with detailed information
- **Data Collection**: Gather product name, seller info, price, shipping costs, and more
- **Google Sheets Integration**: Automatically sync search results to Google Sheets
- **Real-time Monitoring**: Track products with scheduled updates (every 5 minutes or custom interval)
- **Seller Information**: Extract seller details, ratings, and verification status

## Commands

### `alibaba-search`

Main CLI tool for Alibaba product search and tracking.

```bash
# Search for products
alibaba-search search "product keywords" --pages 5 --sheets

# Monitor products (continuous tracking)
alibaba-search monitor "product keywords" --interval 300 --sheets

# Export existing data to Google Sheets
alibaba-search export --database alibaba_data.db --sheet-name "Product Tracker"

# List tracked products
alibaba-search list

# Get seller contact info (extract from product page)
alibaba-search seller --product-url "https://www.alibaba.com/product-detail/..."
```

## Configuration

Edit `config.json` to customize:

```json
{
  "proxy_provider": "syphoon",
  "api_key": "",
  "default_pages": 10,
  "google_sheets": {
    "enabled": true,
    "sheet_name": "Alibaba Products",
    "spreadsheet_id": ""
  },
  "monitoring": {
    "interval_seconds": 300,
    "notify_on_price_change": true
  }
}
```

## Data Collected

### Product Information
- Product name
- Price range (min/max)
- Minimum order quantity
- Product images
- Certifications
- Reviews and ratings
- Customization options

### Supplier Information
- Supplier name
- Verification status
- Years as gold supplier
- Response rate
- Country/location
- Supplier service score

## Google Sheets Integration

Uses the `gog` skill for Google Drive/Sheets access. Data is automatically formatted in a spreadsheet with:

- Product details
- Pricing information
- Supplier information
- Last updated timestamp
- Price change history

## Monitoring

Set up continuous monitoring with:

```bash
# Monitor every 5 minutes
alibaba-search monitor "led lights" --interval 300

# Monitor with Discord notifications
alibaba-search monitor "led lights" --interval 300 --notify discord
```

Monitoring tracks:
- Price changes
- New sellers
- Stock availability
- Rating changes

## Limitations

### Seller Contact/Chat
Alibaba's messaging system requires authentication and session management. The skill provides:
- Seller contact information extraction
- Company profile links
- WhatsApp/WeChat details (when available)

**Direct chat not supported** due to Alibaba's authentication requirements. Manual contact through Alibaba.com is recommended for direct messaging.

### Rate Limiting
- Uses proxy services (Syphoon/BrightData) to avoid blocking
- Async mode recommended for large scrapes
- Sync mode may trigger CAPTCHAs

## Dependencies

- `aba-cli-scrapper`: Core Alibaba scraping engine
- `gog` skill: Google Sheets integration
- Proxy service API key (Syphoon or BrightData)

## Setup

See `README.md` for detailed installation and configuration instructions.
