/**
 * Simple in-memory cache for Cloud Function execution
 * Note: This cache is per-execution and does not persist across function calls
 */
class Cache {
    constructor() {
        this.store = new Map();
    }

    /**
     * Get value from cache
     * @param {string} key - Cache key
     * @returns {*} Cached value or undefined
     */
    get(key) {
        const item = this.store.get(key);
        if (!item) return undefined;

        // Check if expired
        if (item.expiry && Date.now() > item.expiry) {
            this.store.delete(key);
            return undefined;
        }

        return item.value;
    }

    /**
     * Set value in cache
     * @param {string} key - Cache key
     * @param {*} value - Value to cache
     * @param {number} ttlMs - Time to live in milliseconds (optional)
     */
    set(key, value, ttlMs = null) {
        const item = {
            value,
            expiry: ttlMs ? Date.now() + ttlMs : null
        };
        this.store.set(key, item);
    }

    /**
     * Check if key exists and is not expired
     * @param {string} key - Cache key
     * @returns {boolean}
     */
    has(key) {
        return this.get(key) !== undefined;
    }

    /**
     * Clear all cached items
     */
    clear() {
        this.store.clear();
    }
}

// Export singleton instance
module.exports = new Cache();
