const { AccessToken } = require('livekit-server-sdk');
const sdk = require('node-appwrite');

module.exports = async (req, res) => {
  const client = new sdk.Client();
  const databases = new sdk.Databases(client);

  // Check for environment variables
  if (
    !process.env.LIVEKIT_API_KEY ||
    !process.env.LIVEKIT_API_SECRET ||
    !process.env.LIVEKIT_URL ||
    !process.env.APPWRITE_FUNCTION_ENDPOINT ||
    !process.env.APPWRITE_FUNCTION_PROJECT_ID ||
    !process.env.APPWRITE_API_KEY ||
    !process.env.DATABASE_ID ||
    !process.env.CALLS_COLLECTION_ID
  ) {
    return res.json({
      error: 'Function is not configured correctly. Missing environment variables.'
    }, 500);
  }

  // Initialize Appwrite Client
  client
    .setEndpoint(process.env.APPWRITE_FUNCTION_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  // 1. Verify Authentication
  // Appwrite passes the user ID in the request header if the execution is authorized.
  // We should also check if the user is not 'guest' if we want strict logging in.
  const userId = req.headers['x-appwrite-user-id'];

  if (!userId) {
    return res.json({
      error: 'Unauthorized. Please login to use this function.'
    }, 401);
  }

  // Parse request body
  let body;
  try {
    body = JSON.parse(req.payload);
  } catch (e) {
    return res.json({ error: 'Invalid JSON body.' }, 400);
  }

  const { roomName } = body;
  if (!roomName) {
    return res.json({
      error: 'Missing `roomName` in request body.'
    }, 400);
  }

  // 2. Authorization: Verify user is part of the call
  // We assume 'roomName' is the 'callId' (Document ID) of the call in the 'calls' collection.
  try {
    const callDoc = await databases.getDocument(
      process.env.DATABASE_ID,
      process.env.CALLS_COLLECTION_ID,
      roomName
    );

    const isCaller = callDoc.callerId === userId;
    const isReceiver = callDoc.receiverId === userId;

    if (!isCaller && !isReceiver) {
      console.warn(`User ${userId} attempted to join room ${roomName} without permission.`);
      return res.json({
        error: 'You are not a participant in this call.'
      }, 403);
    }

    // Optional: Check if call is already ended? 
    // For now, we allow re-joining if it's not strictly 'ended' or if we want to allow viewing past history logs (though LiveKit room might be closed).
    // Let's enforce that the call status is not 'ended' to prevent zombie rooms.
    if (callDoc.status === 'ended') {
      return res.json({
        error: 'This call has ended.'
      }, 400);
    }

  } catch (e) {
    console.error(`Error fetching call document: ${e.message}`);
    // If document doesn't exist, user can't join.
    return res.json({
      error: 'Call not found or database error.'
    }, 404);
  }

  // 3. Generate Token
  const at = new AccessToken(process.env.LIVEKIT_API_KEY, process.env.LIVEKIT_API_SECRET, {
    identity: userId,
    ttl: '10m',
  });

  at.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canSubscribe: true,
  });

  return res.json({
    token: at.toJwt(),
  });
};
