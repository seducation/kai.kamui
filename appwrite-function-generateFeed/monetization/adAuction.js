const { DATABASE_ID, COLLECTIONS } = require('../config/constants');
const { Query } = require('node-appwrite');

/**
 * Run ad auction to select best ads for user
 * @param {Object} databases - Appwrite Databases instance
 * @param {Array} userInterests - User's interest tags
 * @param {number} limit - Maximum ads to return
 * @returns {Promise<Array>} Ranked ads by eCPM
 */
async function runAdAuction(databases, userInterests, limit = 5) {
    try {
        // Get active ads matching user interests with available budget
        const adCandidates = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.ADS,
            [
                Query.equal('isActive', true),
                Query.greaterThan('budget', 0),
                Query.limit(20) // Over-fetch for auction
            ]
        );

        // Filter ads that match user interests (client-side filtering)
        const relevantAds = adCandidates.documents.filter(ad => {
            if (!ad.targetTags || ad.targetTags.length === 0) return true; // Untargeted ads
            return ad.targetTags.some(tag => userInterests.includes(tag));
        });

        // Calculate eCPM for each ad
        const rankedAds = relevantAds
            .map(ad => {
                const eCPM = (ad.bidCpm || 0) * (ad.clickProbability || 0.01);
                return {
                    ...ad,
                    eCPM,
                    type: 'ad'
                };
            })
            .sort((a, b) => b.eCPM - a.eCPM)
            .slice(0, limit);

        return rankedAds;
    } catch (error) {
        console.error('Error running ad auction:', error.message);
        return [];
    }
}

module.exports = { runAdAuction };
