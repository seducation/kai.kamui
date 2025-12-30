const { FEED } = require('../config/constants');

/**
 * Calculate diversity score based on creator distribution
 * @param {Array} posts - Array of posts
 * @returns {Object} Creator count map
 */
function buildCreatorCounts(posts) {
    const counts = {};
    posts.forEach(post => {
        const authorId = post.profile_id || post.userId || 'unknown';
        counts[authorId] = (counts[authorId] || 0) + 1;
    });
    return counts;
}

/**
 * Check if feed has good creator diversity
 * @param {Array} posts - Array of posts
 * @returns {boolean} True if diverse
 */
function hasGoodDiversity(posts) {
    const creatorCounts = buildCreatorCounts(posts);
    const maxCount = Math.max(...Object.values(creatorCounts));

    // No creator should have more than MAX_CREATOR_REPEAT posts
    return maxCount <= FEED.MAX_CREATOR_REPEAT;
}

/**
 * Enforce diversity by removing excess posts from same creator
 * @param {Array} posts - Array of posts
 * @returns {Array} Posts with enforced diversity
 */
function enforceDiversity(posts) {
    const creatorCounts = {};
    const result = [];
    let lastCreatorId = null;

    for (const post of posts) {
        // Handle schema change: prefer profile_id, fallback to userId
        const authorId = post.profile_id || post.userId || 'unknown';

        // Skip if same creator as immediately previous post
        if (authorId === lastCreatorId) {
            continue;
        }

        // Skip if creator already has MAX_CREATOR_REPEAT posts
        if ((creatorCounts[authorId] || 0) >= FEED.MAX_CREATOR_REPEAT) {
            continue;
        }

        result.push(post);
        creatorCounts[authorId] = (creatorCounts[authorId] || 0) + 1;
        lastCreatorId = authorId;
    }

    return result;
}

module.exports = { buildCreatorCounts, hasGoodDiversity, enforceDiversity };
