import dotenv from 'dotenv';
import Joi from 'joi';

// Ensure environment variables are loaded
dotenv.config();

const INSECURE_DEFAULT_SECRETS = [
  'supersecretjwtkey_habos_2026_secure',
  'supersecretrefreshjwtkey_habos_2026_secure',
  'your_super_secret_jwt_key_here',
  'secret',
  'password',
  '123456',
];

const envSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test')
    .default('development'),
  PORT: Joi.number().port().default(5000),
  DATABASE_URL: Joi.string().required().messages({
    'any.required': 'DATABASE_URL is required for database connections',
    'string.empty': 'DATABASE_URL cannot be empty',
  }),
  JWT_SECRET: Joi.string().required().min(16).messages({
    'any.required': 'JWT_SECRET is required to sign access tokens',
    'string.min': 'JWT_SECRET must be at least 16 characters long',
  }),
  JWT_REFRESH_SECRET: Joi.string().required().min(16).messages({
    'any.required': 'JWT_REFRESH_SECRET is required to sign refresh tokens',
    'string.min': 'JWT_REFRESH_SECRET must be at least 16 characters long',
  }),
  JWT_EXPIRES_IN: Joi.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: Joi.string().default('30d'),
  ALLOWED_ORIGINS: Joi.string().allow('').optional(),
}).unknown(true);

const { error, value: envVars } = envSchema.validate(process.env, {
  abortEarly: false,
  stripUnknown: false,
});

if (error) {
  const missingOrInvalid = error.details.map((d) => `  - ${d.message}`).join('\n');
  console.error('\n❌ CRITICAL: Environment configuration error at boot:\n' + missingOrInvalid);
  process.exit(1);
}

// Additional production security assertions
if (envVars.NODE_ENV === 'production') {
  const insecureSecrets: string[] = [];

  if (INSECURE_DEFAULT_SECRETS.includes(envVars.JWT_SECRET) || envVars.JWT_SECRET.length < 32) {
    insecureSecrets.push('JWT_SECRET uses an insecure default or is less than 32 characters in production');
  }
  if (INSECURE_DEFAULT_SECRETS.includes(envVars.JWT_REFRESH_SECRET) || envVars.JWT_REFRESH_SECRET.length < 32) {
    insecureSecrets.push('JWT_REFRESH_SECRET uses an insecure default or is less than 32 characters in production');
  }

  if (insecureSecrets.length > 0) {
    console.error('\n❌ CRITICAL: Insecure production environment secrets:\n' + insecureSecrets.map((s) => `  - ${s}`).join('\n'));
    process.exit(1);
  }
}

export interface EnvironmentConfig {
  NODE_ENV: 'development' | 'production' | 'test';
  PORT: number;
  DATABASE_URL: string;
  JWT_SECRET: string;
  JWT_REFRESH_SECRET: string;
  JWT_EXPIRES_IN: string;
  JWT_REFRESH_EXPIRES_IN: string;
  ALLOWED_ORIGINS?: string;
}

export const env: EnvironmentConfig = {
  NODE_ENV: envVars.NODE_ENV,
  PORT: envVars.PORT,
  DATABASE_URL: envVars.DATABASE_URL,
  JWT_SECRET: envVars.JWT_SECRET,
  JWT_REFRESH_SECRET: envVars.JWT_REFRESH_SECRET,
  JWT_EXPIRES_IN: envVars.JWT_EXPIRES_IN,
  JWT_REFRESH_EXPIRES_IN: envVars.JWT_REFRESH_EXPIRES_IN,
  ALLOWED_ORIGINS: envVars.ALLOWED_ORIGINS,
};

export default env;
