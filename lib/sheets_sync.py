"""
Google Sheets synchronization using gog skill
"""

import os
import json
import subprocess
import csv
from pathlib import Path


def upload_to_sheets(csv_file, sheet_name, config):
    """
    Upload CSV data to Google Sheets using gog skill
    
    Args:
        csv_file: Path to CSV file
        sheet_name: Name for the Google Sheet
        config: Configuration dictionary
        
    Returns:
        str: URL to the created/updated spreadsheet
    """
    csv_path = Path(csv_file)
    
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV file not found: {csv_file}")
    
    # Get spreadsheet ID from config
    spreadsheet_id = config.get('google_sheets', {}).get('spreadsheet_id', '')
    
    # Read CSV data
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        data = list(reader)
    
    if not data:
        raise ValueError("CSV file is empty")
    
    # Option 1: Use gog skill if available
    try:
        result = _upload_via_gog(data, sheet_name, spreadsheet_id)
        return result
    except Exception as e:
        print(f"gog skill upload failed: {e}")
        # Fall back to direct API approach
        return _upload_via_api(data, sheet_name, spreadsheet_id)


def _upload_via_gog(data, sheet_name, spreadsheet_id=None):
    """
    Upload using gog skill (preferred method)
    
    This assumes gog skill has a command like:
    gog sheets create "Sheet Name" --data data.csv
    or
    gog sheets update SPREADSHEET_ID --sheet "Sheet Name" --data data.csv
    """
    
    # Check if gog command exists
    gog_check = subprocess.run(['which', 'gog'], capture_output=True)
    
    if gog_check.returncode != 0:
        raise Exception("gog skill not found in PATH")
    
    # For now, use a simple approach: save data and call gog
    # This would need to match actual gog skill interface
    
    # Placeholder - actual gog skill interface would be different
    cmd = ['gog', 'sheets', 'upload', sheet_name]
    
    if spreadsheet_id:
        cmd.extend(['--spreadsheet-id', spreadsheet_id])
    
    # Execute gog command
    # Note: This is a placeholder - actual implementation depends on gog skill
    
    raise NotImplementedError("Direct gog integration pending - use API method")


def _upload_via_api(data, sheet_name, spreadsheet_id=None):
    """
    Upload using Google Sheets API directly
    Requires google-auth and google-api-python-client
    """
    try:
        from google.oauth2 import service_account
        from googleapiclient.discovery import build
    except ImportError:
        raise ImportError(
            "Google Sheets API libraries not installed. "
            "Run: pip install google-auth google-api-python-client"
        )
    
    # Look for credentials
    creds_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    
    if not creds_path:
        # Try common locations
        possible_paths = [
            Path.home() / '.config' / 'gog' / 'credentials.json',
            Path.home() / '.openclaw' / 'gog' / 'credentials.json',
            Path(__file__).parent.parent / 'credentials.json'
        ]
        
        for path in possible_paths:
            if path.exists():
                creds_path = str(path)
                break
    
    if not creds_path or not Path(creds_path).exists():
        raise FileNotFoundError(
            "Google credentials not found. "
            "Set GOOGLE_APPLICATION_CREDENTIALS or place credentials.json in skill directory"
        )
    
    # Authenticate
    SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
    creds = service_account.Credentials.from_service_account_file(
        creds_path, scopes=SCOPES
    )
    
    service = build('sheets', 'v4', credentials=creds)
    
    # Create or update spreadsheet
    if spreadsheet_id:
        # Update existing spreadsheet
        return _update_spreadsheet(service, spreadsheet_id, sheet_name, data)
    else:
        # Create new spreadsheet
        return _create_spreadsheet(service, sheet_name, data)


def _create_spreadsheet(service, title, data):
    """Create a new Google Spreadsheet"""
    
    spreadsheet = {
        'properties': {
            'title': title
        },
        'sheets': [{
            'properties': {
                'title': 'Products'
            }
        }]
    }
    
    spreadsheet = service.spreadsheets().create(
        body=spreadsheet,
        fields='spreadsheetId,spreadsheetUrl'
    ).execute()
    
    spreadsheet_id = spreadsheet.get('spreadsheetId')
    
    # Add data
    _update_sheet_data(service, spreadsheet_id, 'Products', data)
    
    return spreadsheet.get('spreadsheetUrl')


def _update_spreadsheet(service, spreadsheet_id, sheet_name, data):
    """Update existing Google Spreadsheet"""
    
    # Check if sheet exists, create if not
    spreadsheet = service.spreadsheets().get(
        spreadsheetId=spreadsheet_id
    ).execute()
    
    sheet_exists = any(
        sheet['properties']['title'] == sheet_name 
        for sheet in spreadsheet.get('sheets', [])
    )
    
    if not sheet_exists:
        # Create new sheet
        request = {
            'addSheet': {
                'properties': {
                    'title': sheet_name
                }
            }
        }
        
        service.spreadsheets().batchUpdate(
            spreadsheetId=spreadsheet_id,
            body={'requests': [request]}
        ).execute()
    
    # Update data
    _update_sheet_data(service, spreadsheet_id, sheet_name, data)
    
    return f"https://docs.google.com/spreadsheets/d/{spreadsheet_id}"


def _update_sheet_data(service, spreadsheet_id, sheet_name, data):
    """Update sheet with data"""
    
    # Clear existing data
    service.spreadsheets().values().clear(
        spreadsheetId=spreadsheet_id,
        range=f"{sheet_name}!A1:ZZ"
    ).execute()
    
    # Update with new data
    body = {
        'values': data
    }
    
    service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=f"{sheet_name}!A1",
        valueInputOption='RAW',
        body=body
    ).execute()
    
    # Format header row
    requests = [{
        'repeatCell': {
            'range': {
                'sheetId': _get_sheet_id(service, spreadsheet_id, sheet_name),
                'startRowIndex': 0,
                'endRowIndex': 1
            },
            'cell': {
                'userEnteredFormat': {
                    'backgroundColor': {
                        'red': 0.2,
                        'green': 0.6,
                        'blue': 0.9
                    },
                    'textFormat': {
                        'bold': True,
                        'foregroundColor': {
                            'red': 1.0,
                            'green': 1.0,
                            'blue': 1.0
                        }
                    }
                }
            },
            'fields': 'userEnteredFormat(backgroundColor,textFormat)'
        }
    }]
    
    service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id,
        body={'requests': requests}
    ).execute()


def _get_sheet_id(service, spreadsheet_id, sheet_name):
    """Get sheet ID by name"""
    spreadsheet = service.spreadsheets().get(
        spreadsheetId=spreadsheet_id
    ).execute()
    
    for sheet in spreadsheet.get('sheets', []):
        if sheet['properties']['title'] == sheet_name:
            return sheet['properties']['sheetId']
    
    return 0
