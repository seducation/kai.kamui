const { ENGAGEMENT } = require('../config/constants');

/**
 * Infer user's patience state from behavioral signals
 * @param {Array} signals - Recent user signals
 * @returns {Object} Patience state and recommendations
 */
function inferPatience(signals) {
    if (!signals || signals.length === 0) {
        return {
            state: 'neutral',
            adAggression: 'medium',
            isPatient: true,
            isRapidScrolling: false,
            isEngaged: false
        };
    }

    // Calculate average dwell time
    const dwellSignals = signals.filter(s => s.dwellTime);
    const avgDwell = dwellSignals.length > 0
        ? dwellSignals.reduce((sum, s) => sum + s.dwellTime, 0) / dwellSignals.length
        : 0;

    // Calculate scroll rate (posts per second)
    if (signals.length >= 2) {
        const firstTime = new Date(signals[0].createdAt).getTime();
        const lastTime = new Date(signals[signals.length - 1].createdAt).getTime();
        const timeSpan = (lastTime - firstTime) / 1000; // seconds
        const scrollRate = timeSpan > 0 ? signals.length / timeSpan : 0;

        // Engaged state: high dwell time, low scroll rate
        if (avgDwell > ENGAGEMENT.DWELL_ENGAGED && scrollRate < 1) {
            return {
                state: 'engaged',
                adAggression: 'medium',
                isPatient: true,
                isRapidScrolling: false,
                isEngaged: true,
                engagementStreak: true
            };
        }

        // Impatient state: low dwell time or high scroll rate
        if (avgDwell < ENGAGEMENT.DWELL_SKIP || scrollRate > ENGAGEMENT.RAPID_SCROLL_RATE) {
            return {
                state: 'impatient',
                adAggression: 'low',
                isPatient: false,
                isRapidScrolling: true,
                isEngaged: false
            };
        }
    }

    // Default neutral state
    return {
        state: 'neutral',
        adAggression: 'medium',
        isPatient: true,
        isRapidScrolling: false,
        isEngaged: false
    };
}

/**
 * Build session context from user signals and data
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {Array} recentSignals - Recent user signals
 * @param {Object} user - User object
 * @returns {Object} Session context
 */
async function buildSessionContext(databases, userId, recentSignals, user) {
    const patience = inferPatience(recentSignals);

    // Count consecutive likes
    let consecutiveLikes = 0;
    for (const signal of recentSignals) {
        if (signal.signalType === 'like') {
            consecutiveLikes++;
        } else {
            break;
        }
    }

    return {
        ...patience,
        consecutiveLikes,
        userFollowCount: user.followingCount || 0,
        creatorCounts: {},
        justSawAd: false,
        adFatigue: false
    };
}

module.exports = { inferPatience, buildSessionContext };
