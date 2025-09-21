// Utility functions for formatting that we can test
export const formatAddress = (address: string): string => {
  if (!address) return '';
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

export const formatTokenAmount = (amount: string | number, decimals: number = 2): string => {
  const num = typeof amount === 'string' ? parseFloat(amount) : amount;
  return num.toFixed(decimals);
};

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const validateUrl = (url: string): boolean => {
  try {
    new URL(url);
    return true;
  } catch {
    return false;
  }
};

// Tests
describe('Formatter Utilities', () => {
  describe('formatAddress', () => {
    test('formats Ethereum address correctly', () => {
      const address = '0x1234567890123456789012345678901234567890';
      expect(formatAddress(address)).toBe('0x1234...7890');
    });

    test('handles empty address', () => {
      expect(formatAddress('')).toBe('');
    });

    test('handles short address', () => {
      const shortAddress = '0x123';
      expect(formatAddress(shortAddress)).toBe('0x123...x123');
    });
  });

  describe('formatTokenAmount', () => {
    test('formats number with default decimals', () => {
      expect(formatTokenAmount(123.456)).toBe('123.46');
    });

    test('formats string number', () => {
      expect(formatTokenAmount('123.456')).toBe('123.46');
    });

    test('formats with custom decimals', () => {
      expect(formatTokenAmount(123.456789, 4)).toBe('123.4568');
    });

    test('handles zero', () => {
      expect(formatTokenAmount(0)).toBe('0.00');
    });
  });

  describe('validateEmail', () => {
    test('validates correct email', () => {
      expect(validateEmail('test@example.com')).toBe(true);
    });

    test('rejects invalid email', () => {
      expect(validateEmail('invalid-email')).toBe(false);
      expect(validateEmail('test@')).toBe(false);
      expect(validateEmail('@example.com')).toBe(false);
    });
  });

  describe('validateUrl', () => {
    test('validates correct URL', () => {
      expect(validateUrl('https://example.com')).toBe(true);
      expect(validateUrl('http://test.org')).toBe(true);
    });

    test('rejects invalid URL', () => {
      expect(validateUrl('not-a-url')).toBe(false);
      expect(validateUrl('://invalid')).toBe(false);
    });
  });
});
