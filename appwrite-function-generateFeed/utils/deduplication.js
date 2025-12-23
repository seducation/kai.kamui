const { DATABASE_ID, COLLECTIONS, TIME } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Get posts that user has seen recently
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {string} sessionId - Current session ID
 * @returns {Promise<Set>} Set of seen post IDs
 */
async function getSeenPostIds(databases, userId, sessionId) {
    try {
        // Get posts seen in last 24 hours
        const seenDocs = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.SEEN_POSTS,
            [
                Query.equal('userId', userId),
                Query.greaterThan('seenAt', new Date(Date.now() - TIME.DAY).toISOString()),
                Query.limit(500)
            ]
        );

        const seenPostIds = seenDocs.documents.map(d => d.postId);

        // Get posts user quickly skipped (dwell < 1s) in last week
        const skipped = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.USER_SIGNALS,
            [
                Query.equal('userId', userId),
                Query.equal('signalType', 'skip'),
                Query.greaterThan('createdAt', new Date(Date.now() - TIME.WEEK).toISOString()),
                Query.limit(200)
            ]
        );

        const skippedPostIds = skipped.documents
            .filter(s => s.dwellTime && s.dwellTime < 1000)
            .map(s => s.postId);

        return new Set([...seenPostIds, ...skippedPostIds]);
    } catch (error) {
        console.error('Error getting seen posts:', error.message);
        return new Set();
    }
}

/**
 * Filter out posts that user has already seen
 * @param {Array} posts - Array of posts
 * @param {Set} seenPostIds - Set of seen post IDs
 * @returns {Array} Filtered posts
 */
function deduplicatePosts(posts, seenPostIds) {
    return posts.filter(post => {
        // Ads are never deduplicated (different ad instances)
        if (post.type === 'ad' || post.type === 'carousel') {
            return true;
        }
        return !seenPostIds.has(post.postId || post.$id);
    });
}

/**
 * Record posts as seen by user
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {string} sessionId - Current session ID
 * @param {Array} posts - Array of posts shown to user
 */
async function recordSeenPosts(databases, userId, sessionId, posts) {
    try {
        const { ID } = require('node-appwrite');

        for (const post of posts) {
            // Only record organic posts (not ads or carousels)
            if (post.type === 'post') {
                await databases.createDocument(
                    DATABASE_ID,
                    COLLECTIONS.SEEN_POSTS,
                    ID.unique(),
                    {
                        userId,
                        sessionId,
                        postId: post.postId || post.$id,
                        seenAt: new Date().toISOString()
                    }
                );
            }
        }
    } catch (error) {
        console.error('Error recording seen posts:', error.message);
    }
}

module.exports = { getSeenPostIds, deduplicatePosts, recordSeenPosts };
