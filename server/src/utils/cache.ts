interface CacheEntry<T> {
  value: T;
  expiresAt: number | null; // null means no expiration
}

class MemoryCache {
  private store = new Map<string, CacheEntry<any>>();
  private cleanupInterval: NodeJS.Timeout | null = null;

  constructor(cleanupIntervalMs: number = 60 * 1000) {
    // Periodically remove expired keys
    this.cleanupInterval = setInterval(() => {
      this.purgeExpired();
    }, cleanupIntervalMs);

    if (this.cleanupInterval.unref) {
      this.cleanupInterval.unref(); // Allow Node process to exit cleanly if running tests
    }
  }

  /**
   * Retrieve cached value by key. Returns null if expired or missing.
   */
  get<T>(key: string): T | null {
    const entry = this.store.get(key);
    if (!entry) return null;

    if (entry.expiresAt && entry.expiresAt < Date.now()) {
      this.store.delete(key);
      return null;
    }

    return entry.value as T;
  }

  /**
   * Set value in cache with optional TTL in seconds.
   */
  set<T>(key: string, value: T, ttlSeconds: number = 60): void {
    const expiresAt = ttlSeconds > 0 ? Date.now() + ttlSeconds * 1000 : null;
    this.store.set(key, { value, expiresAt });
  }

  /**
   * Delete a specific key from the cache.
   */
  del(key: string): boolean {
    return this.store.delete(key);
  }

  /**
   * Invalidate all keys matching a given prefix or substring pattern.
   * e.g. invalidatePattern('dashboard:user-123')
   */
  invalidatePattern(pattern: string): number {
    let count = 0;
    for (const key of this.store.keys()) {
      if (key.includes(pattern)) {
        this.store.delete(key);
        count++;
      }
    }
    return count;
  }

  /**
   * Clear entire cache store.
   */
  clear(): void {
    this.store.clear();
  }

  /**
   * Current number of stored keys.
   */
  size(): number {
    return this.store.size;
  }

  private purgeExpired(): void {
    const now = Date.now();
    for (const [key, entry] of this.store.entries()) {
      if (entry.expiresAt && entry.expiresAt < now) {
        this.store.delete(key);
      }
    }
  }
}

export const cache = new MemoryCache();
export default cache;
