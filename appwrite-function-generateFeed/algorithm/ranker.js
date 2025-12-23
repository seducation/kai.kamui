const { RANKING_WEIGHTS } = require('../config/constants');
const {
    getUserAffinity,
    calculateRecencyScore,
    calculateEngagementScore,
    calculateDiversityScore
} = require('./signals');

/**
 * Calculate final ranking score for a post
 * @param {Object} post - Post object
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {Object} sessionContext - Session context data
 * @returns {Promise<number>} Final ranking score
 */
async function calculateScore(post, databases, userId, sessionContext) {
    // Base signals
    const recencyScore = calculateRecencyScore(post.createdAt);
    const engagementScore = calculateEngagementScore(post.engagementScore || 0);
    const diversityScore = calculateDiversityScore(post.userId, sessionContext.creatorCounts);

    // User-specific affinity
    const affinityScore = await getUserAffinity(databases, userId, post.userId);

    // Session-specific adjustments
    let sessionBoost = 0;
    if (sessionContext.isPatient) sessionBoost += 0.1;
    if (sessionContext.justSawAd) sessionBoost += 0.15; // Boost organic after ad

    // Dynamic weights based on session
    let weights = { ...RANKING_WEIGHTS };

    if (sessionContext.isRapidScrolling) {
        weights.recency = 0.35; // Prioritize freshness
        weights.engagement = 0.25;
    }

    if (sessionContext.isEngaged) {
        weights.engagement = 0.40; // Prioritize engagement
        weights.recency = 0.20;
    }

    const finalScore =
        (recencyScore * weights.RECENCY) +
        (engagementScore * weights.ENGAGEMENT) +
        (diversityScore * weights.DIVERSITY) +
        (affinityScore * weights.AFFINITY) +
        (sessionBoost * weights.SESSION);

    return finalScore;
}

/**
 * Rank all candidate posts using multi-signal algorithm
 * @param {Array} candidates - Array of candidate posts
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {Object} sessionContext - Session context data
 * @returns {Promise<Array>} Ranked posts (sorted by score descending)
 */
async function rankPosts(candidates, databases, userId, sessionContext) {
    // Calculate scores for all posts
    const scoredPosts = await Promise.all(
        candidates.map(async (post) => {
            const score = await calculateScore(post, databases, userId, sessionContext);
            return {
                ...post,
                rankingScore: score
            };
        })
    );

    // Sort by score descending
    return scoredPosts.sort((a, b) => b.rankingScore - a.rankingScore);
}

module.exports = { rankPosts, calculateScore };
