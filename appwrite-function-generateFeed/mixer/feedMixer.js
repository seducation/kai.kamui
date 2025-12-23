const { enforceDiversity } = require('../algorithm/diversity');
const { injectAds } = require('../monetization/adInjector');
const { injectCarousel } = require('../engagement/carouselInjector');
const { deduplicatePosts } = require('../utils/deduplication');
const { FEED } = require('../config/constants');

/**
 * Mix organic posts with ads and carousels to create final feed
 * This is the main orchestrator that combines all feed elements
 * 
 * @param {Array} organicPosts - Ranked organic posts
 * @param {Array} ads - Ads sorted by eCPM
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {Object} sessionContext - Session context data
 * @param {Set} seenPostIds - Set of already seen post IDs
 * @returns {Promise<Array>} Final mixed feed
 */
async function mixFeed(organicPosts, ads, databases, userId, sessionContext, seenPostIds) {
    // Step 1: Deduplicate posts
    const uniquePosts = deduplicatePosts(organicPosts, seenPostIds);

    // Step 2: Enforce creator diversity
    const diversePosts = enforceDiversity(uniquePosts);

    // Step 3: Inject ads at opportunity windows
    let feedWithAds = injectAds(diversePosts, ads, sessionContext);

    // Step 4: Inject carousel if eligible
    const finalFeed = await injectCarousel(feedWithAds, databases, userId, sessionContext);

    // Step 5: Apply final limit
    return finalFeed.slice(0, FEED.MAX_LIMIT);
}

/**
 * Create paginated subset of feed
 * @param {Array} feed - Complete feed array
 * @param {number} offset - Starting index
 * @param {number} limit - Number of items to return
 * @returns {Object} Paginated feed with metadata
 */
function paginateFeed(feed, offset, limit) {
    const items = feed.slice(offset, offset + limit);

    return {
        items,
        offset,
        limit,
        total: feed.length,
        hasMore: (offset + limit) < feed.length
    };
}

module.exports = { mixFeed, paginateFeed };
