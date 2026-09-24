import winston from 'winston';
import path from 'path';
import fs from 'fs';
import { Request } from 'express';

// Ensure logs directory exists
const logsDir = path.resolve(process.cwd(), 'logs');
if (!fs.existsSync(logsDir)) {
  try {
    fs.mkdirSync(logsDir, { recursive: true });
  } catch {
    // Ignore error if cannot create directory
  }
}

const auditTransport = new winston.transports.File({
  filename: path.join(logsDir, 'audit.log'),
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
});

const consoleTransport = new winston.transports.Console({
  level: 'info',
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message, ...meta }) => {
      const metaStr = Object.keys(meta).length ? ` | ${JSON.stringify(meta)}` : '';
      return `[AUDIT] ${timestamp} [${level}]: ${message}${metaStr}`;
    })
  ),
});

const auditWinston = winston.createLogger({
  level: 'info',
  transports: [
    auditTransport,
    ...(process.env.NODE_ENV !== 'test' ? [consoleTransport] : []),
  ],
});

export type AuditAction =
  | 'AUTH_LOGIN_SUCCESS'
  | 'AUTH_LOGIN_FAILURE'
  | 'AUTH_REGISTER_SUCCESS'
  | 'AUTH_REGISTER_FAILURE'
  | 'AUTH_TOKEN_REFRESH_SUCCESS'
  | 'AUTH_TOKEN_REFRESH_FAILURE'
  | 'AUTH_TOKEN_REUSE_DETECTED'
  | 'AUTH_PROFILE_UPDATE'
  | 'AUTH_PREFERENCES_UPDATE'
  | 'SECURITY_EVENT';

export type AuditStatus = 'SUCCESS' | 'FAILURE' | 'WARNING' | 'CRITICAL';

export interface AuditPayload {
  action: AuditAction;
  status: AuditStatus;
  userId?: string | null;
  ip?: string;
  userAgent?: string;
  details?: Record<string, any>;
}

export const logAuditEvent = (payload: AuditPayload): void => {
  const { action, status, userId, ip, userAgent, details } = payload;
  const logLevel = status === 'CRITICAL' || status === 'WARNING' ? 'warn' : 'info';

  auditWinston.log(logLevel, `[${action}] - Status: ${status}`, {
    action,
    status,
    userId: userId || 'anonymous',
    ip: ip || 'unknown',
    userAgent: userAgent || 'unknown',
    details: details || {},
    timestamp: new Date().toISOString(),
  });
};

export const logAuditFromReq = (
  req: Request,
  action: AuditAction,
  status: AuditStatus,
  details?: Record<string, any>,
  userId?: string | null
): void => {
  const clientIp = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || req.ip;
  const userAgent = req.headers['user-agent'] as string | undefined;

  logAuditEvent({
    action,
    status,
    userId: userId || (req as any).user?.id || null,
    ip: clientIp,
    userAgent,
    details,
  });
};

export default {
  logAuditEvent,
  logAuditFromReq,
};
