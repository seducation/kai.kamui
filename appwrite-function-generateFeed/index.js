const { Client, Databases, Query, ID } = require('node-appwrite');
const { DATABASE_ID, COLLECTIONS, POOL_SIZES, COLD_START_POOL_SIZES, FEED } = require('./config/constants');

// Import candidate generators
const { getFollowedPosts } = require('./candidates/followedPosts');
const { getInterestBasedPosts } = require('./candidates/interestBased');
const { getTrendingPosts } = require('./candidates/trending');
const { getFreshPosts } = require('./candidates/fresh');
const { getViralPosts, getExplorationPosts } = require('./candidates/exploration');

// Import algorithm modules
const { rankPosts } = require('./algorithm/ranker');
const { buildCreatorCounts } = require('./algorithm/diversity');

// Import monetization modules
const { runAdAuction } = require('./monetization/adAuction');
const { checkAdFatigue } = require('./monetization/fatigue');

// Import engagement modules
const { buildSessionContext } = require('./engagement/patience');

// Import mixer and utilities
const { mixFeed, paginateFeed } = require('./mixer/feedMixer');
const { getSeenPostIds, recordSeenPosts } = require('./utils/deduplication');

/**
 * Main Cloud Function entry point
 * Generates personalized feed for a user
 */
module.exports = async ({ req, res, log, error }) => {
    try {
        // Parse request data
        const { sessionId, offset = 0, limit = FEED.DEFAULT_LIMIT, postType = 'all' } = JSON.parse(req.body || '{}');

        // Initialize Appwrite client
        const client = new Client()
            .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
            .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
            .setKey(process.env.APPWRITE_API_KEY);

        const databases = new Databases(client);

        // Get user ID from authorization header
        const userId = req.headers['x-appwrite-user-id'];
        if (!userId) {
            return res.json({ error: 'Unauthorized' }, 401);
        }

        log(`Generating feed for user: ${userId}, session: ${sessionId}, postType: ${postType}`);

        // Validate pagination parameters
        const safeOffset = Math.max(0, parseInt(offset) || 0);
        const safeLimit = Math.min(FEED.MAX_LIMIT, Math.max(1, parseInt(limit) || FEED.DEFAULT_LIMIT));

        // Step 1: Get user profile and recent signals
        const [user, recentSignals] = await Promise.all([
            databases.getDocument(DATABASE_ID, COLLECTIONS.USERS, userId),
            databases.listDocuments(DATABASE_ID, COLLECTIONS.USER_SIGNALS, [
                Query.equal('userId', userId),
                Query.orderDesc('createdAt'),
                Query.limit(20)
            ])
        ]);

        log(`User interests: ${user.interests?.join(', ')}`);

        // Step 2: Build session context (patience, engagement state)
        let sessionContext = await buildSessionContext(
            databases,
            userId,
            recentSignals.documents,
            user
        );

        log(`Session state: ${sessionContext.state}, Ad aggression: ${sessionContext.adAggression}`);

        // Step 3: Check ad fatigue
        const adFatigued = await checkAdFatigue(databases, userId, sessionId);
        sessionContext.adFatigue = adFatigued;

        // Step 4: Determine if cold start (new user)
        const isColdStart = user.followingCount < 5;

        // Create a base query for postType if it's not 'all'
        const postTypeQueries = [];
        if (postType && postType !== 'all') {
            postTypeQueries.push(Query.equal('postType', postType));
        }

        // Step 5: Generate candidates from multiple pools (in parallel)
        log('Fetching candidates from multiple pools...');

        const [ 
            followedPosts, 
            interestPosts, 
            trendingPosts, 
            freshPosts, 
            viralPosts, 
            explorationPosts 
        ] = await Promise.all([
            isColdStart ? Promise.resolve([]) : getFollowedPosts(databases, userId, POOL_SIZES.FOLLOWED, ...postTypeQueries),
            getInterestBasedPosts(
                databases,
                user.interests || [],
                isColdStart ? COLD_START_POOL_SIZES.INTEREST : POOL_SIZES.INTEREST,
                ...postTypeQueries
            ),
            getTrendingPosts(
                databases,
                isColdStart ? COLD_START_POOL_SIZES.TRENDING : POOL_SIZES.TRENDING,
                ...postTypeQueries
            ),
            getFreshPosts(databases, POOL_SIZES.FRESH, ...postTypeQueries),
            getViralPosts(databases, POOL_SIZES.VIRAL, ...postTypeQueries),
            getExplorationPosts(
                databases,
                isColdStart ? COLD_START_POOL_SIZES.EXPLORATION : POOL_SIZES.EXPLORATION,
                ...postTypeQueries
            )
        ]);

        // Combine all candidates
        const allCandidates = [
            ...followedPosts,
            ...interestPosts,
            ...trendingPosts,
            ...freshPosts,
            ...viralPosts,
            ...explorationPosts
        ];

        log(`Total candidates: ${allCandidates.length}`);

        // Initialize creator counts for diversity scoring
        sessionContext.creatorCounts = buildCreatorCounts(allCandidates);

        // Step 6: Rank posts using multi-signal algorithm
        log('Ranking posts...');
        const rankedPosts = await rankPosts(allCandidates, databases, userId, sessionContext);

        // Step 7: Run ad auction
        let ads = [];
        if (!sessionContext.adFatigue && sessionContext.adAggression !== 'none') {
            log('Running ad auction...');
            ads = await runAdAuction(databases, user.interests || [], 5);
            log(`Selected ${ads.length} ads`);
        }

        // Step 8: Get seen posts for deduplication
        const seenPostIds = await getSeenPostIds(databases, userId, sessionId);
        log(`User has seen ${seenPostIds.size} posts recently`);

        // Step 9: Mix feed (organic + ads + carousels)
        log('Mixing final feed...');
        const mixedFeed = await mixFeed(
            rankedPosts,
            ads,
            databases,
            userId,
            sessionContext,
            seenPostIds
        );

        // Step 10: Paginate
        const paginatedFeed = paginateFeed(mixedFeed, safeOffset, safeLimit);

        // Step 11: Record shown posts
        await recordSeenPosts(databases, userId, sessionId, paginatedFeed.items);

        log(`Feed generated: ${paginatedFeed.items.length} items (${paginatedFeed.hasMore ? 'more available' : 'end reached'})`);

        // Return feed
        return res.json({
            success: true,
            ...paginatedFeed,
            sessionContext: {
                state: sessionContext.state,
                adFatigue: sessionContext.adFatigue
            }
        });

    } catch (err) {
        error('Feed generation error:', err.message, err.stack);
        return res.json({
            success: false,
            error: 'Failed to generate feed',
            message: err.message
        }, 500);
    }
};
