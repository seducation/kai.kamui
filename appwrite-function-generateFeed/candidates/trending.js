const { DATABASE_ID, COLLECTIONS, POOL_SIZES, ENGAGEMENT } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Fetch trending posts with high engagement
 * @param {Object} databases - Appwrite Databases instance
 * @param {number} limit - Maximum posts to fetch
 * @returns {Promise<Array>} Array of posts
 */
async function getTrendingPosts(databases, limit = POOL_SIZES.TRENDING) {
    try {
        // Get posts with high engagement score
        const posts = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.POSTS,
            [
                Query.greaterThan('engagementScore', ENGAGEMENT.HIGH_ENGAGEMENT),
                Query.orderDesc('engagementScore'),
                Query.orderDesc('createdAt'),
                Query.limit(limit)
            ]
        );

        return posts.documents.map(p => ({
            ...p,
            sourcePool: 'trending',
            type: 'post'
        }));
    } catch (error) {
        console.error('Error fetching trending posts:', error.message);
        return [];
    }
}

module.exports = { getTrendingPosts };
