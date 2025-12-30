const { DATABASE_ID, COLLECTIONS, POOL_SIZES } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Fetch viral posts (marked as viral)
 * @param {Object} databases - Appwrite Databases instance
 * @param {number} limit - Maximum posts to fetch
 * @returns {Promise<Array>} Array of posts
 */
async function getViralPosts(databases, limit = POOL_SIZES.VIRAL, ...extraQueries) {
    try {
        const posts = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.POSTS,
            [
                Query.equal('status', 'active'),
                Query.equal('isHidden', false),
                // Query.greaterThan('likes', 100), // Removed due to missing schema
                // Query.orderDesc('likes'), // Removed due to missing schema
                Query.orderDesc('timestamp'),
                Query.limit(limit),
                ...extraQueries
            ]
        );

        return posts.documents.map(p => ({
            ...p,
            sourcePool: 'viral',
            type: 'post',
            engagementScore: (p.likes || 0) + (p.comments || 0) + ((p.shares || 0) * 2)
        }));
    } catch (error) {
        console.error('Error fetching viral posts:', error.message);
        return [];
    }
}

/**
 * Fetch random exploration posts for serendipity
 * @param {Object} databases - Appwrite Databases instance
 * @param {number} limit - Maximum posts to fetch
 * @returns {Promise<Array>} Array of posts
 */
async function getExplorationPosts(databases, limit = POOL_SIZES.EXPLORATION, ...extraQueries) {
    try {
        // Get recent posts (random sampling simulated by recent posts)
        const posts = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.POSTS,
            [
                // Query.equal('status', 'active'),
                // Query.equal('isHidden', false),
                Query.orderDesc('timestamp'),
                Query.limit(100), // Get larger pool
                ...extraQueries
            ]
        );

        // Randomly sample from the pool
        const shuffled = posts.documents.sort(() => 0.5 - Math.random());

        return shuffled.slice(0, limit).map(p => ({
            ...p,
            sourcePool: 'exploration',
            type: 'post',
            engagementScore: (p.likes || 0) + (p.comments || 0) + ((p.shares || 0) * 2)
        }));
    } catch (error) {
        console.error('Error fetching exploration posts:', error.message);
        return [];
    }
}

module.exports = { getViralPosts, getExplorationPosts };
