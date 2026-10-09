import crypto from 'crypto';

export type LogLevel = 'INFO' | 'SUCCESS' | 'WARN' | 'ERROR' | 'SECURITY';

export interface AuditLogEntry {
  id: string;
  timestamp: string;
  level: LogLevel;
  category: string;
  message: string;
  details?: any;
  user?: string;
  ip?: string;
}
