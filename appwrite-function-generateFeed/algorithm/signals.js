const { DATABASE_ID, COLLECTIONS, TIME } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Calculate user's affinity score for a specific creator
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {string} creatorId - Creator user ID
 * @returns {Promise<number>} Affinity score
 */
async function getUserAffinity(databases, userId, creatorId) {
    try {
        // Get user's past interactions with this creator
        const signals = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.USER_SIGNALS,
            [
                Query.equal('userId', userId),
                Query.greaterThan('createdAt', new Date(Date.now() - TIME.WEEK).toISOString()),
                Query.limit(100)
            ]
        );

        // Count interactions by type
        let likeCount = 0;
        let commentCount = 0;
        let shareCount = 0;

        signals.documents.forEach(signal => {
            if (signal.signalType === 'like') likeCount++;
            if (signal.signalType === 'comment') commentCount++;
            if (signal.signalType === 'share') shareCount++;
        });

        // Weighted affinity score
        return (likeCount * 1) + (commentCount * 3) + (shareCount * 5);
    } catch (error) {
        console.error('Error calculating affinity:', error.message);
        return 0;
    }
}

/**
 * Calculate recency score (decay over time)
 * @param {Date} createdAt - Post creation date
 * @returns {number} Recency score
 */
function calculateRecencyScore(createdAt) {
    const ageInHours = (Date.now() - new Date(createdAt).getTime()) / TIME.HOUR;
    return 1 / (1 + ageInHours);
}

/**
 * Calculate engagement score (logarithmic)
 * @param {number} engagementScore - Raw engagement count
 * @returns {number} Normalized engagement score
 */
function calculateEngagementScore(engagementScore) {
    return Math.log(1 + engagementScore);
}

/**
 * Calculate diversity score (penalize repetition)
 * @param {string} creatorId - Creator user ID
 * @param {Object} creatorCounts - Map of creator ID to count
 * @returns {number} Diversity score
 */
function calculateDiversityScore(creatorId, creatorCounts) {
    const count = creatorCounts[creatorId] || 0;
    return 1 / (1 + count);
}

module.exports = {
    getUserAffinity,
    calculateRecencyScore,
    calculateEngagementScore,
    calculateDiversityScore
};
