const { AD_RULES, DATABASE_ID, COLLECTIONS } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Check if user is experiencing ad fatigue
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {string} sessionId - Current session ID
 * @returns {Promise<boolean>} True if user is fatigued
 */
async function checkAdFatigue(databases, userId, sessionId) {
    try {
        // Get recent ad interactions in this session
        const recentSignals = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.USER_SIGNALS,
            [
                Query.equal('userId', userId),
                Query.equal('signalType', 'skip'),
                Query.orderDesc('createdAt'),
                Query.limit(10)
            ]
        );

        // Count consecutive ad skips
        let consecutiveSkips = 0;
        for (const signal of recentSignals.documents) {
            if (signal.dwellTime && signal.dwellTime < 1000) {
                consecutiveSkips++;
            } else {
                break; // Not consecutive anymore
            }

            if (consecutiveSkips >= AD_RULES.FATIGUE_THRESHOLD) {
                return true;
            }
        }

        return false;
    } catch (error) {
        console.error('Error checking ad fatigue:', error.message);
        return false;
    }
}

/**
 * Get ad frequency preference for user
 * @param {Object} user - User object
 * @returns {number} Frequency multiplier
 */
function getAdFrequencyMultiplier(user) {
    const preference = user.adPreference || 'medium';

    switch (preference) {
        case 'low':
            return 0.5; // Show fewer ads
        case 'high':
            return 1.5; // Show more ads (for power users who don't mind)
        case 'medium':
        default:
            return 1.0;
    }
}

module.exports = { checkAdFatigue, getAdFrequencyMultiplier };
