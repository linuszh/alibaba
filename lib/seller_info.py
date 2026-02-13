"""
Extract seller contact information from Alibaba product pages
"""

import requests
from bs4 import BeautifulSoup
import re


def extract_seller_info(product_url):
    """
    Extract seller information from Alibaba product page
    
    Args:
        product_url: Full URL to Alibaba product page
        
    Returns:
        dict: Seller information including name, verification, contact details
    """
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(product_url, headers=headers, timeout=10)
        response.raise_for_status()
    except Exception as e:
        return {
            'error': f'Failed to fetch page: {str(e)}',
            'url': product_url
        }
    
    soup = BeautifulSoup(response.content, 'html.parser')
    
    seller_info = {
        'url': product_url,
        'name': 'Unknown',
        'verification': 'Unknown',
        'years': 'Unknown',
        'country': 'Unknown',
        'profile_url': None,
        'contact': {}
    }
    
    # Extract seller name
    try:
        seller_name_elem = soup.find('a', {'class': re.compile('company.*name')})
        if not seller_name_elem:
            seller_name_elem = soup.find('div', {'class': re.compile('company.*name')})
        if seller_name_elem:
            seller_info['name'] = seller_name_elem.get_text(strip=True)
    except:
        pass
    
    # Extract verification status
    try:
        verified_elem = soup.find('span', {'class': re.compile('verified')})
        if verified_elem:
            seller_info['verification'] = 'Verified'
        else:
            seller_info['verification'] = 'Unverified'
    except:
        pass
    
    # Extract years as supplier
    try:
        years_elem = soup.find(text=re.compile(r'\d+\s*YRS'))
        if years_elem:
            years_match = re.search(r'(\d+)\s*YRS', years_elem)
            if years_match:
                seller_info['years'] = f"{years_match.group(1)} years"
    except:
        pass
    
    # Extract country
    try:
        country_elem = soup.find('span', {'class': re.compile('country')})
        if not country_elem:
            country_elem = soup.find(text=re.compile(r'(China|India|USA|Turkey|Pakistan)'))
        if country_elem:
            seller_info['country'] = country_elem if isinstance(country_elem, str) else country_elem.get_text(strip=True)
    except:
        pass
    
    # Extract company profile URL
    try:
        company_link = soup.find('a', href=re.compile(r'/company/'))
        if company_link:
            href = company_link.get('href')
            if href.startswith('//'):
                seller_info['profile_url'] = 'https:' + href
            elif href.startswith('/'):
                seller_info['profile_url'] = 'https://www.alibaba.com' + href
            else:
                seller_info['profile_url'] = href
    except:
        pass
    
    # Try to extract contact information (limited on product pages)
    try:
        # Look for contact button/link
        contact_elem = soup.find('a', {'class': re.compile('contact')})
        if contact_elem:
            seller_info['contact']['contact_url'] = contact_elem.get('href', '')
        
        # Look for WhatsApp/WeChat (sometimes shown)
        whatsapp = soup.find(text=re.compile(r'WhatsApp[:|\s]+[\+\d\s\-\(\)]+'))
        if whatsapp:
            seller_info['contact']['whatsapp'] = whatsapp.strip()
        
        wechat = soup.find(text=re.compile(r'WeChat[:|\s]+[\w\d]+'))
        if wechat:
            seller_info['contact']['wechat'] = wechat.strip()
            
    except:
        pass
    
    # Add note about direct messaging
    seller_info['note'] = (
        "Direct messaging requires Alibaba account login. "
        "Visit the product page or company profile to send inquiries."
    )
    
    return seller_info


def get_chat_instructions():
    """
    Return instructions for contacting sellers via Alibaba
    """
    return """
    📧 How to Contact Alibaba Sellers:
    
    1. LOGIN REQUIRED
       - Create/login to Alibaba account at alibaba.com
       - Verified accounts get better response rates
    
    2. CONTACT METHODS
       - "Contact Supplier" button on product page
       - Trade Messenger (Alibaba's chat system)
       - Email inquiry form
       - Phone (if listed on company profile)
    
    3. BEST PRACTICES
       - Be specific about quantity and requirements
       - Ask for detailed quotations
       - Request product samples
       - Verify supplier credentials
       - Use Alibaba Trade Assurance for payment protection
    
    4. RESPONSE TIME
       - Most suppliers respond within 24-48 hours
       - Gold/Verified suppliers typically faster
       - Check "Response Rate" on supplier profile
    
    Note: Automated chat via this tool is not possible due to
    Alibaba's authentication and anti-bot measures.
    """
