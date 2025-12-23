const { DATABASE_ID, COLLECTIONS, POOL_SIZES, TIME } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Fetch posts from users that the current user follows
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {number} limit - Maximum posts to fetch
 * @returns {Promise<Array>} Array of posts
 */
async function getFollowedPosts(databases, userId, limit = POOL_SIZES.FOLLOWED) {
    try {
        // Get users that current user follows
        const follows = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.FOLLOWS,
            [Query.equal('followerId', userId), Query.limit(1000)]
        );

        const followedUserIds = follows.documents.map(f => f.followingId);

        if (followedUserIds.length === 0) {
            return [];
        }

        // Get recent posts from followed users
        const posts = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.POSTS,
            [
                Query.equal('userId', followedUserIds),
                Query.orderDesc('createdAt'),
                Query.limit(limit)
            ]
        );

        return posts.documents.map(p => ({
            ...p,
            sourcePool: 'followed',
            type: 'post'
        }));
    } catch (error) {
        console.error('Error fetching followed posts:', error.message);
        return [];
    }
}

module.exports = { getFollowedPosts };
