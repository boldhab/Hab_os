-- Migration to upgrade transactions and budgets to Decimal(12, 2) and add persistent IdempotencyKey table

-- 1. Alter Transaction amount to NUMERIC(12, 2)
ALTER TABLE "transactions" 
ALTER COLUMN "amount" TYPE DECIMAL(12, 2) USING "amount"::DECIMAL(12, 2);

-- 2. Alter Budget monthlyLimit to NUMERIC(12, 2)
ALTER TABLE "budgets" 
ALTER COLUMN "monthlyLimit" TYPE DECIMAL(12, 2) USING "monthlyLimit"::DECIMAL(12, 2);

-- 3. Create idempotency_keys table
CREATE TABLE IF NOT EXISTS "idempotency_keys" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "response" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "idempotency_keys_pkey" PRIMARY KEY ("id")
);

-- 4. Create unique constraint and index on idempotency_keys
CREATE UNIQUE INDEX IF NOT EXISTS "idempotency_keys_userId_key_key" ON "idempotency_keys"("userId", "key");
CREATE INDEX IF NOT EXISTS "idempotency_keys_expiresAt_idx" ON "idempotency_keys"("expiresAt");

-- 5. Add foreign key relation
ALTER TABLE "idempotency_keys" 
ADD CONSTRAINT "idempotency_keys_userId_fkey" 
FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
