const { DATABASE_ID, COLLECTIONS, CAROUSEL_RULES, TIME } = require('../config/constants');
const { Query, ID } = require('node-appwrite');

/**
 * Check if user has seen a carousel type recently
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {string} carouselType - Type of carousel
 * @returns {Promise<boolean>} True if carousel was seen recently
 */
async function hasSeenCarouselRecently(databases, userId, carouselType) {
    try {
        const recentCarousels = await databases.listDocuments(
            DATABASE_ID,
            COLLECTIONS.CAROUSEL_MEMORY,
            [
                Query.equal('userId', userId),
                Query.equal('carouselType', carouselType),
                Query.greaterThan('seenAt', new Date(Date.now() - (CAROUSEL_RULES.COOLDOWN_HOURS * TIME.HOUR)).toISOString())
            ]
        );

        return recentCarousels.documents.length > 0;
    } catch (error) {
        console.error('Error checking carousel memory:', error.message);
        return false;
    }
}

/**
 * Generate carousel content based on type
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} carouselType - Type of carousel
 * @param {string} userId - Current user ID
 * @returns {Promise<Object>} Carousel data
 */
async function generateCarousel(databases, carouselType, userId) {
    try {
        let items = [];
        let title = '';

        switch (carouselType) {
            case 'trending_creators':
                title = 'Trending Creators';
                // Get users with highest engagement
                const creators = await databases.listDocuments(
                    DATABASE_ID,
                    COLLECTIONS.USERS,
                    [
                        Query.equal('isCreator', true),
                        Query.orderDesc('followerCount'),
                        Query.limit(10)
                    ]
                );
                items = creators.documents.map(c => ({
                    id: c.userId,
                    title: c.username,
                    imageUrl: c.profileImage || 'https://via.placeholder.com/150',
                    subtitle: `${c.followerCount} followers`
                }));
                break;

            case 'suggested_communities':
                title = 'Communities You Might Like';
                // Placeholder - would fetch communities based on interests
                items = [];
                break;

            case 'similar_posts':
                title = 'More Like This';
                // Placeholder - would fetch similar posts
                items = [];
                break;

            default:
                title = 'Discover';
                items = [];
        }

        return {
            carouselType,
            title,
            items
        };
    } catch (error) {
        console.error('Error generating carousel:', error.message);
        return { carouselType, title: 'Discover', items: [] };
    }
}

/**
 * Inject carousel into feed if eligible
 * @param {Array} posts - Array of posts
 * @param {Object} databases - Appwrite Databases instance
 * @param {string} userId - Current user ID
 * @param {Object} sessionContext - Session context data
 * @returns {Promise<Array>} Posts with carousel injected
 */
async function injectCarousel(posts, databases, userId, sessionContext) {
    // Don't inject if user is in engagement streak
    if (sessionContext.engagementStreak) {
        return posts;
    }

    // Don't inject if feed is too short
    if (posts.length < CAROUSEL_RULES.INJECTION_INDEX) {
        return posts;
    }

    // Determine carousel type based on user context
    let carouselType = 'trending_creators';

    if (sessionContext.userFollowCount < 10) {
        carouselType = 'suggested_communities';
    } else if (sessionContext.consecutiveLikes >= 3) {
        carouselType = 'similar_posts';
    }

    // Check if user saw this type recently
    const seenRecently = await hasSeenCarouselRecently(databases, userId, carouselType);
    if (seenRecently) {
        return posts;
    }

    // Generate carousel
    const carousel = await generateCarousel(databases, carouselType, userId);

    // Skip if carousel has no items
    if (carousel.items.length === 0) {
        return posts;
    }

    // Inject at configured index
    const result = [...posts];
    result.splice(CAROUSEL_RULES.INJECTION_INDEX, 0, {
        type: 'carousel',
        ...carousel
    });

    // Record in memory
    try {
        await databases.createDocument(
            DATABASE_ID,
            COLLECTIONS.CAROUSEL_MEMORY,
            ID.unique(),
            {
                userId,
                carouselType,
                seenAt: new Date().toISOString()
            }
        );
    } catch (error) {
        console.error('Error recording carousel memory:', error.message);
    }

    return result;
}

module.exports = { injectCarousel, generateCarousel, hasSeenCarouselRecently };
