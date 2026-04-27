export function normalizeIndianPhone(input: string): string {
  const raw = (input ?? '').trim();
  const digits = raw.replace(/\D/g, '');

  // 10-digit local mobile (starting 6-9) -> +91XXXXXXXXXX
  if (/^[6-9]\d{9}$/.test(digits)) {
    return `+91${digits}`;
  }

  // 12-digit with country code but missing plus -> +91XXXXXXXXXX
  if (/^91[6-9]\d{9}$/.test(digits)) {
    return `+${digits}`;
  }

  // Already in +91 format
  if (/^\+91[6-9]\d{9}$/.test(raw)) {
    return raw;
  }

  return raw;
}

