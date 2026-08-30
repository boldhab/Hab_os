import crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12; // Standard for AES-GCM

/**
 * Derives a 32-byte key buffer from ENCRYPTION_KEY environment variable or a development fallback key.
 */
const getEncryptionKey = (): Buffer => {
  const secret = process.env.ENCRYPTION_KEY || 'habos_default_dev_encryption_secret_key_32_bytes!';
  return crypto.createHash('sha256').update(secret).digest();
};

/**
 * Encrypts a plaintext string using AES-256-GCM.
 * Output format: "ivHex:authTagHex:ciphertextHex"
 */
export const encryptToken = (plaintext: string): string => {
  if (!plaintext || plaintext.trim() === '') {
    return '';
  }

  const key = getEncryptionKey();
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  const authTag = cipher.getAuthTag().toString('hex');

  return `${iv.toString('hex')}:${authTag}:${encrypted}`;
};

/**
 * Decrypts an encrypted token string ("ivHex:authTagHex:ciphertextHex").
 * Includes backward compatibility for unencrypted legacy tokens.
 */
export const decryptToken = (ciphertext: string): string => {
  if (!ciphertext || ciphertext.trim() === '') {
    return '';
  }

  const parts = ciphertext.split(':');
  if (parts.length !== 3) {
    // Legacy unencrypted token format fallback
    return ciphertext;
  }

  const [ivHex, authTagHex, encryptedHex] = parts;

  try {
    const key = getEncryptionKey();
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);

    decipher.setAuthTag(authTag);
    let decrypted = decipher.update(encryptedHex, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (err) {
    // If decryption fails (e.g. key mismatch or legacy token)
    return ciphertext;
  }
};

export default {
  encryptToken,
  decryptToken,
};
