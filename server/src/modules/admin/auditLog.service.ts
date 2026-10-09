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

class AuditLogService {
  private logs: AuditLogEntry[] = [];
  private readonly maxEntries = 300;

  constructor() {
    this.seedInitialLogs();
  }

  private seedInitialLogs(): void {
    const now = Date.now();
    const seeds: Array<Omit<AuditLogEntry, 'id' | 'timestamp'>> = [
      {
        level: 'INFO',
        category: 'SYSTEM',
        message: 'Server started successfully',
        details: { version: '1.0.0', runtime: 'Node.js', env: process.env.NODE_ENV || 'development' },
        user: 'system',
      },
      {
        level: 'SUCCESS',
        category: 'SCHEDULER',
        message: 'Scheduled jobs initialized (4 active)',
        details: { workers: ['notificationProcessor', 'habitStreakDecay', 'dailyLifeScore', 'idempotencyCleanup'] },
        user: 'system',
      },
      {
        level: 'INFO',
        category: 'DATABASE',
        message: 'Database connection established',
        details: { multiTenant: true },
        user: 'system',
      },
      {
        level: 'SECURITY',
        category: 'AUTH',
        message: 'Admin authentication verified',
        details: { adminEmail: 'admin@habos.dev' },
        user: 'system',
      },
      {
        level: 'INFO',
        category: 'SYSTEM',
        message: 'Life Score engine initialized',
        user: 'system',
      },
    ];

    seeds.forEach((seed, index) => {
      this.logs.push({
        id: crypto.randomUUID(),
        timestamp: new Date(now - (seeds.length - index) * 60000).toISOString(),
        ...seed,
      });
    });
  }

  public log(entry: Omit<AuditLogEntry, 'id' | 'timestamp'>): AuditLogEntry {
    const fullEntry: AuditLogEntry = {
      id: crypto.randomUUID(),
      timestamp: new Date().toISOString(),
      ...entry,
    };

    this.logs.unshift(fullEntry);
    if (this.logs.length > this.maxEntries) {
      this.logs.pop();
    }
    return fullEntry;
  }
}
