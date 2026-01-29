/**
 * Voice Call Validator - System-level emergency number blocker
 * 
 * Usage:
 *   const { validateNumber } = require('./voice-call-validator');
 *   const result = validateNumber('+14155551234');
 *   if (!result.allowed) throw new Error(result.reason);
 * 
 * CLI:
 *   node voice-call-validator.js +14155551234
 */

const EMERGENCY_NUMBERS = new Set([
  // US/Canada
  '911', '933',
  // EU Universal
  '112',
  // UK
  '999', '111', '101', '105',
  // Australia
  '000', '106',
  // Switzerland
  '117', '118', '143', '144', '145', '147',
  // Germany
  '110', '116117',
  // France
  '15', '17', '18', '114', '115', '119',
  // Japan
  '110', '119', '118',
]);

const BLOCKED_FULL_NUMBERS = new Set([
  '1911',    // US +1 911
  '44999',   // UK +44 999
  '44112',   // UK +44 112
  '41117',   // CH +41 117
  '41118',   // CH +41 118
  '41144',   // CH +41 144
  '41143',   // CH +41 143
  '49110',   // DE +49 110
  '49112',   // DE +49 112
  '61000',   // AU +61 000
  '81110',   // JP +81 110
  '81119',   // JP +81 119
  '33112',   // FR +33 112
  '3315',    // FR +33 15
  '3317',    // FR +33 17
  '3318',    // FR +33 18
]);

function validateNumber(phone) {
  if (!phone || typeof phone !== 'string') {
    return { allowed: false, reason: 'No phone number provided' };
  }

  // Normalize: remove everything except digits and leading +
  const normalized = phone.replace(/[^\d+]/g, '');
  const digitsOnly = normalized.replace(/\+/g, '');

  // Check minimum length
  if (digitsOnly.length < 7) {
    return {
      allowed: false,
      reason: `Number too short (${digitsOnly.length} digits) - likely emergency or short code`,
      number: phone,
    };
  }

  // Check against full blocked numbers
  if (BLOCKED_FULL_NUMBERS.has(digitsOnly)) {
    return {
      allowed: false,
      reason: 'Blocked: Known emergency number',
      number: phone,
    };
  }

  // Check if ends with emergency number (after country code)
  for (const emergency of EMERGENCY_NUMBERS) {
    if (digitsOnly.endsWith(emergency) && digitsOnly.length <= emergency.length + 3) {
      return {
        allowed: false,
        reason: `Blocked: Matches emergency pattern (${emergency})`,
        number: phone,
      };
    }
  }

  // Check E.164 format
  const warnings = [];
  if (!phone.startsWith('+')) {
    warnings.push('Number not in E.164 format (missing +)');
  }

  return {
    allowed: true,
    number: phone,
    normalized,
    warnings: warnings.length > 0 ? warnings : undefined,
  };
}

// CLI mode
if (require.main === module) {
  const phone = process.argv[2];
  const result = validateNumber(phone);
  
  if (result.allowed) {
    console.log(`ALLOWED: ${result.number}`);
    if (result.warnings) {
      result.warnings.forEach(w => console.warn(`WARNING: ${w}`));
    }
    process.exit(0);
  } else {
    console.error(`BLOCKED: ${result.reason}`);
    console.error(`Number: ${result.number || phone}`);
    process.exit(1);
  }
}

module.exports = { validateNumber, EMERGENCY_NUMBERS, BLOCKED_FULL_NUMBERS };
