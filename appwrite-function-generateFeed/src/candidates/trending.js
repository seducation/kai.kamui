const { DATABASE_ID, COLLECTIONS, POOL_SIZES, ENGAGEMENT } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Fetch trending posts with high engagement
 * @param {Object} databases - Appwrite Databases instance
 * @param {number} limit - Maximum posts to fetch
 * @returns {Promise<Array>} Array of posts
 */
async function getTrendingPosts(databases, limit = POOL_SIZES.TRENDING, ...extraQueries) {
    try {
        // Since 'likes' count is not on the post document, we aggregate from the 'likes' collection
        // 1. Get recent likes (last 24 hours) to determine what's trending NOW
        const oneDayAgo = new Date(Date.now() - (24 * 60 * 60 * 1000)).toISOString();

        const recentLikes = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.LIKES,
            [
                Query.greaterThan('timestamp', oneDayAgo),
                Query.limit(300) // Sample size for trending
            ]
        );

        if (recentLikes.documents.length === 0) {
            // Fallback to recent posts if no likes found
            const fallbackPosts = await databases.listDocuments(
                DATABASE_ID,
                COLLECTIONS.POSTS,
                [
                    // Query.equal('status', 'active'),
                    // Query.equal('isHidden', false),
                    Query.orderDesc('timestamp'),
                    Query.limit(limit),
                    ...extraQueries
                ]
            );
            return fallbackPosts.documents.map(p => ({ ...p, sourcePool: 'trending', type: 'post' }));
        }

        // 2. Aggregate likes by postId
        const likeCounts = {};
        recentLikes.documents.forEach(like => {
            const pid = like.post_id;
            if (pid) {
                likeCounts[pid] = (likeCounts[pid] || 0) + 1;
            }
        });

        // 3. Sort postIds by count
        const topPostIds = Object.keys(likeCounts)
            .sort((a, b) => likeCounts[b] - likeCounts[a])
            .slice(0, limit);

        if (topPostIds.length === 0) return [];

        // 4. Fetch the actual posts
        const posts = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.POSTS,
            [
                Query.equal('$id', topPostIds),
                // Query.equal('status', 'active'),
                // Query.equal('isHidden', false)
                ...extraQueries
            ]
        );

        // 5. Map and preserve order (Appwrite might return out of order)
        // Also we can inject the calculated like count as a temporary engagement score
        const postMap = new Map(posts.documents.map(p => [p.$id, p]));

        return topPostIds
            .map(id => postMap.get(id))
            .filter(p => p !== undefined)
            .map(p => ({
                ...p,
                sourcePool: 'trending',
                type: 'post',
                engagementScore: (likeCounts[p.$id] || 0) * 5 // Weight likes heavily for trending
            }));

    } catch (error) {
        console.error('Error fetching trending posts:', error.message);
        return [];
    }
}

module.exports = { getTrendingPosts };
