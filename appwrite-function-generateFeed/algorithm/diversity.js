const { FEED } = require('../config/constants');

/**
 * Calculate diversity score based on creator distribution
 * @param {Array} posts - Array of posts
 * @returns {Object} Creator count map
 */
function buildCreatorCounts(posts) {
    const counts = {};
    posts.forEach(post => {
        counts[post.userId] = (counts[post.userId] || 0) + 1;
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
        // Skip if same creator as immediately previous post
        if (post.userId === lastCreatorId) {
            continue;
        }

        // Skip if creator already has MAX_CREATOR_REPEAT posts
        if (creatorCounts[post.userId] >= FEED.MAX_CREATOR_REPEAT) {
            continue;
        }

        result.push(post);
        creatorCounts[post.userId] = (creatorCounts[post.userId] || 0) + 1;
        lastCreatorId = post.userId;
    }

    return result;
}

module.exports = { buildCreatorCounts, hasGoodDiversity, enforceDiversity };
