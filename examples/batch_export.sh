#!/bin/bash
# Example: Batch export all databases to Google Sheets

SHEET_NAME="${1:-Alibaba Product Tracker}"

echo "Exporting all databases to Google Sheets: $SHEET_NAME"

for db in ../data/*.db; do
    if [ -f "$db" ]; then
        echo "Exporting: $(basename $db)"
        ../alibaba-search export --database "$db" --sheet-name "$SHEET_NAME"
    fi
done

echo "Export complete!"
