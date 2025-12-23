const { AD_RULES } = require('../config/constants');

/**
 * Find opportunity windows for ad injection
 * @param {Array} organicPosts - Array of organic posts
 * @param {Object} sessionContext - Session context data
 * @returns {Array} Array of indexes where ads can be injected
 */
function findAdOpportunities(organicPosts, sessionContext) {
    const opportunities = [];
    let lastAdIndex = -100; // Initialize far back
    let adCount = 0;

    for (let i = 0; i < organicPosts.length; i++) {
        const postsSinceLastAd = i - lastAdIndex;

        // Check all constraints
        const meetsFrequency = postsSinceLastAd >= AD_RULES.FREQUENCY_CAP;
        const meetsCooldown = postsSinceLastAd >= AD_RULES.COOLDOWN;
        const notFatigued = !sessionContext.adFatigue;
        const notInStreak = !sessionContext.engagementStreak;
        const underSessionCap = i < 20 ? adCount < AD_RULES.SESSION_CAP : true;
        const notInWarmup = i >= 3; // Don't show ads in first 3 posts

        if (meetsFrequency && meetsCooldown && notFatigued && notInStreak && underSessionCap && notInWarmup) {
            opportunities.push(i);
            lastAdIndex = i;
            adCount++;
        }
    }

    return opportunities;
}

/**
 * Inject ads into organic feed at optimal positions
 * @param {Array} organicPosts - Array of organic posts
 * @param {Array} ads - Array of ads sorted by eCPM
 * @param {Object} sessionContext - Session context data
 * @returns {Array} Combined array with ads injected
 */
function injectAds(organicPosts, ads, sessionContext) {
    if (!ads || ads.length === 0) {
        return organicPosts;
    }

    const opportunities = findAdOpportunities(organicPosts, sessionContext);

    // Clone organic posts
    const result = [...organicPosts];
    let adIndex = 0;

    // Inject ads at opportunity windows (in reverse to maintain indices)
    for (let i = opportunities.length - 1; i >= 0 && adIndex < ads.length; i--) {
        const position = opportunities[i];
        result.splice(position, 0, ads[adIndex]);
        adIndex++;
    }

    return result;
}

module.exports = { findAdOpportunities, injectAds };
