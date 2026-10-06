-- Add lifecycle tracking to existing focus sessions without resetting the database.
ALTER TABLE "focus_sessions"
ADD COLUMN "status" TEXT NOT NULL DEFAULT 'RUNNING';

-- Existing rows with an end time are historical completed sessions.
UPDATE "focus_sessions"
SET "status" = 'COMPLETED'
WHERE "endTime" IS NOT NULL;

ALTER TABLE "focus_sessions"
ADD COLUMN "cancelledAt" TIMESTAMP(3),
ADD COLUMN "timeEntryId" TEXT;

CREATE UNIQUE INDEX "focus_sessions_timeEntryId_key"
ON "focus_sessions"("timeEntryId");

CREATE INDEX "focus_sessions_userId_status_idx"
ON "focus_sessions"("userId", "status");

ALTER TABLE "focus_sessions"
ADD CONSTRAINT "focus_sessions_timeEntryId_fkey"
FOREIGN KEY ("timeEntryId") REFERENCES "time_entries"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
