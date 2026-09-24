# HABos API Versioning & Evolution Strategy

This document specifies the versioning lifecycle, deprecation protocol, and changelog management for the HABos REST API.

---

## 1. Versioning Architecture

HABos adheres to a **URI Path-Based Semantic Versioning** strategy:

```
https://api.habos.dev/api/v{MAJOR}/{resource}
```

* **Current Active Version**: `/api/v1/`
* **Patch & Minor Updates**: Backward-compatible bug fixes and additions (new endpoints, optional query params, non-breaking response fields) are delivered within the existing major version prefix (`/api/v1/`).
* **Major Updates**: Breaking changes (renamed fields, altered schemas, removed endpoints) require a new major version prefix (`/api/v2/`).

---

## 2. Breaking Change & Deprecation Policy

When an endpoint or schema must be deprecated or replaced:

1. **Advance Notice**: Deprecations are announced at least **90 days** prior to sunsetting.
2. **RFC 8594 Standard Headers**: The deprecated endpoint will return standard deprecation headers on all responses:
   - `Deprecation: true`
   - `Sunset: <HTTP-Date>` (the hard decommission timestamp)
   - `Link: </api/v2/...>; rel="successor-version"`
   - `X-API-Deprecation-Notice: <human-readable message>`
3. **Migration Guide**: A documented guide mapping old endpoints and payload shapes to the successor version will be published in `/docs/api/migrations/`.
4. **Decommissioning**: Once the sunset date is reached, the deprecated endpoint returns `HTTP 410 Gone`.

---

## 3. Pagination Standard

All unbounded or growing collection endpoints (`/tasks`, `/focus`, `/gym`, etc.) follow the standardized pagination envelope:

### Request Query Parameters
* `page`: Integer $\ge 1$ (default: `1`).
* `limit`: Integer $\ge 1$, capped at `100` (default: `20`).
* `cursor`: String, unique item ID for high-performance cursor pagination.

### Response Envelope
```json
{
  "success": true,
  "data": {
    "data": [ ...items... ],
    "pagination": {
      "total": 142,
      "page": 1,
      "limit": 20,
      "totalPages": 8,
      "hasMore": true,
      "nextCursor": "d3b07384-d113-4632-..."
    }
  },
  "message": "Tasks retrieved"
}
```

---

## 4. API Changelog

### Version 1.1.0 (Current)
* **Security Hardening**:
  - Fail-fast environment and boot secret validation schema (`config/env.ts`).
  - IP-based rate limiting on authentication routes (`/login`, `/register`, `/refresh`) and API endpoints.
  - Refresh token rotation with cryptographic `jti` nonces and token family theft detection.
  - Request body schema validation using Joi before hitting Prisma.
  - Dedicated security audit logging (`logs/audit.log`).
  - Strict CORS origin whitelisting in production.
* **Performance & Architecture**:
  - Parallel query execution on `/api/v1/dashboard` using `Promise.all`.
  - In-memory TTL caching with mutation-based invalidation on dashboard feed.
  - Dedicated service layer extraction (`tasks.service.ts`) with user ownership checks.
  - Standardized pagination on `/tasks`, `/focus`, and `/gym`.
  - Background job runner (`scheduler.ts`) featuring habit streak decay, notification dispatcher, and daily Life Score snapshots.

### Version 1.0.0 (MVP)
* Initial 24 domain modules implemented with Prisma ORM and Express REST routes.
