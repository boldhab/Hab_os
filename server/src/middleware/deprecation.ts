import { Request, Response, NextFunction } from 'express';

export interface DeprecationOptions {
  sunsetDate?: string; // ISO Date or RFC 1123 date string, e.g. "2026-12-31T23:59:59Z"
  alternativeUrl?: string; // Next version endpoint, e.g. "/api/v2/tasks"
  message?: string;
}

/**
 * RFC 8594 Compliant Deprecation Middleware
 * Emits standard Deprecation and Sunset headers to inform API consumers of impending changes.
 */
export const deprecate = (options: DeprecationOptions = {}) => {
  return (_req: Request, res: Response, next: NextFunction): void => {
    res.setHeader('Deprecation', 'true');

    if (options.sunsetDate) {
      const date = new Date(options.sunsetDate);
      res.setHeader('Sunset', date.toUTCString());
    }

    if (options.alternativeUrl) {
      res.setHeader('Link', `<${options.alternativeUrl}>; rel="successor-version"`);
    }

    if (options.message) {
      res.setHeader('X-API-Deprecation-Notice', options.message);
    }

    next();
  };
};

export default deprecate;
