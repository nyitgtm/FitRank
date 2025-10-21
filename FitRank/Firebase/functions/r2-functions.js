// Firebase Cloud Function for Secure R2 Uploads
// Location: functions/index.js
// 
// Install dependencies:
// npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');

admin.initializeApp();

// SECURITY: Store R2 credentials as environment variables
// Set via: firebase functions:config:set r2.account_id="YOUR_ACCOUNT_ID"
const R2_CONFIG = {
  accountId: functions.config().r2?.account_id || "98157e1e740679ce8626dffd45f5af05",
  accessKeyId: functions.config().r2?.access_key_id || "05a8e6f2b28dd2a72bd29abd72e47559",
  secretAccessKey: functions.config().r2?.secret_access_key || "d7920955f0a52af3463fdc31403a488cdaf3a6bbe5974ebf6d02b3b88126559e",
  bucketName: "videos",
  publicURL: "https://pub-4f8e728946614c7887df487ba187d3ad.r2.dev"
};

// Initialize R2 S3 client
const r2Client = new S3Client({
  region: 'auto',
  endpoint: `https://${R2_CONFIG.accountId}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: R2_CONFIG.accessKeyId,
    secretAccessKey: R2_CONFIG.secretAccessKey,
  },
});

/**
 * Generate a presigned URL for video upload
 * This keeps R2 credentials secure on the backend
 * 
 * Usage from iOS:
 * POST /generatePresignedUploadURL
 * Body: { "workoutId": "unique-workout-id" }
 */
exports.generatePresignedUploadURL = functions.https.onRequest(async (req, res) => {
  // CORS headers
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    // Verify authentication (optional but recommended)
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split('Bearer ')[1];
      try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        console.log('Authenticated user:', decodedToken.uid);
      } catch (error) {
        console.warn('Invalid token, but continuing...');
      }
    }

    // Get workout ID from request
    const { workoutId } = req.body;

    if (!workoutId) {
      res.status(400).json({ error: 'workoutId is required' });
      return;
    }

    // Generate presigned URL
    const fileName = `${workoutId}.mp4`;
    
    const command = new PutObjectCommand({
      Bucket: R2_CONFIG.bucketName,
      Key: fileName,
      ContentType: 'video/mp4',
    });

    // URL expires in 15 minutes (enough time to upload)
    const uploadUrl = await getSignedUrl(r2Client, command, { expiresIn: 900 });
    
    // Return presigned URL
    res.status(200).json({
      uploadUrl: uploadUrl,
      publicUrl: `${R2_CONFIG.publicURL}/${fileName}`,
      expiresIn: 900
    });

  } catch (error) {
    console.error('Error generating presigned URL:', error);
    res.status(500).json({ error: 'Failed to generate upload URL' });
  }
});

/**
 * Alternative: Callable function (better authentication)
 */
exports.generatePresignedUploadURLCallable = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to upload videos'
    );
  }

  const { workoutId } = data;

  if (!workoutId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'workoutId is required'
    );
  }

  try {
    const fileName = `${workoutId}.mp4`;
    
    const command = new PutObjectCommand({
      Bucket: R2_CONFIG.bucketName,
      Key: fileName,
      ContentType: 'video/mp4',
    });

    const uploadUrl = await getSignedUrl(r2Client, command, { expiresIn: 900 });
    
    return {
      uploadUrl: uploadUrl,
      publicUrl: `${R2_CONFIG.publicURL}/${fileName}`,
      expiresIn: 900
    };

  } catch (error) {
    console.error('Error generating presigned URL:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to generate upload URL'
    );
  }
});

/**
 * Delete video from R2 (admin only)
 */
exports.deleteVideoFromR2 = functions.https.onCall(async (data, context) => {
  // Verify admin
  if (!context.auth || !context.auth.token.admin) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only admins can delete videos'
    );
  }

  const { workoutId } = data;

  if (!workoutId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'workoutId is required'
    );
  }

  try {
    const { DeleteObjectCommand } = require('@aws-sdk/client-s3');
    const fileName = `${workoutId}.mp4`;
    
    const command = new DeleteObjectCommand({
      Bucket: R2_CONFIG.bucketName,
      Key: fileName,
    });

    await r2Client.send(command);
    
    return { success: true, message: 'Video deleted successfully' };

  } catch (error) {
    console.error('Error deleting video:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to delete video'
    );
  }
});
