import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

const db = admin.firestore();
// Get OpenAI API key from Runtime Config (set via firebase functions:config:set openai.key="...")
const OPENAI_API_KEY = functions.config().openai?.key || process.env.OPENAI_API_KEY || "";
const GOOGLE_PLAY_PACKAGE_NAME = "com.saynode.homhom";

// Log if API key is configured (but don't log the actual key!)
if (OPENAI_API_KEY) {
  console.log("✅ OpenAI API key configured");
} else {
  console.warn("⚠️ WARNING: OpenAI API key not configured. Set with: firebase functions:config:set openai.key=\"sk-...\"");
}

interface ReceiptValidationRequest {
  purchaseToken: string;
  productId: string;
  packageName: string;
}

interface MealProcessingRequest {
  imageBase64: string;
  userPreferences?: {
    dietaryRestrictions?: string[];
    calorieTarget?: number;
  };
}

/**
 * Validate Google Play purchase receipt
 * Called when user completes an in-app purchase
 */
export const validatePlayPurchase = functions.https.onCall(
  async (data: ReceiptValidationRequest, context) => {
    // Verify user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const { purchaseToken, productId, packageName } = data;

    try {
      // Verify with Google Play API
      const isValid = await verifyGooglePlayReceipt(
        packageName,
        productId,
        purchaseToken
      );

      if (!isValid) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Invalid purchase token"
        );
      }

      // Get HOM pack details
      const homPack = getHomPackDetails(productId);
      if (!homPack) {
        throw new functions.https.HttpsError(
          "not-found",
          "Unknown product"
        );
      }

      // Update user balance in Firestore
      const userRef = db.collection("users").doc(userId);
      await userRef.update({
        balance: admin.firestore.FieldValue.increment(homPack.homs),
        lastPurchaseAt: admin.firestore.Timestamp.now(),
        updatedAt: admin.firestore.Timestamp.now(),
      });

      // Log transaction
      await db.collection("users").doc(userId).collection("transactions").add({
        type: "purchase",
        productId,
        homsAdded: homPack.homs,
        price: homPack.price,
        purchaseTokenHash: hashToken(purchaseToken),
        timestamp: admin.firestore.Timestamp.now(),
      });

      return {
        success: true,
        homsAdded: homPack.homs,
        message: `Successfully added ${homPack.homs} HOMs to your account`,
      };
    } catch (error: any) {
      console.error("Purchase validation error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to validate purchase"
      );
    }
  }
);

/**
 * Helper function to process meal after user data is confirmed
 * ✅ ONLY deducts HOMs if analysis succeeds AND returns food data (foods.length > 0)
 */
async function processMealForUser(
  userId: string,
  imageBase64: string,
  userPreferences: any,
  userData: any
): Promise<any> {
  // Check if user is unlimited or has HOMs
  if (!userData.isUnlimited && userData.balance <= 0) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Insufficient HOMs. Please purchase more or add API key."
    );
  }

  // Call OpenAI Vision API to analyze meal (BEFORE deducting HOMs)
  const mealAnalysis = await analyzeImageWithOpenAI(imageBase64, userPreferences);

  // ✅ Check if analysis returned food data
  const foods = mealAnalysis.foods || [];
  if (!Array.isArray(foods) || foods.length === 0) {
    // No food detected - DON'T deduct HOMs!
    console.log('❌ No food detected in analysis. NOT deducting HOMs.');
    
    // Still log the failed analysis attempt
    await db.collection("users").doc(userId).collection("meals").add({
      ...mealAnalysis,
      processedAt: admin.firestore.Timestamp.now(),
      homsUsed: 0,
      success: false,
      reason: 'No food detected'
    }).catch(err => console.warn('Failed to log meal:', err));

    // Return current balance (NOT decremented)
    return {
      success: false,
      analysis: mealAnalysis,
      remainingHoms: userData.isUnlimited ? "unlimited" : (userData.balance || 10),
      reason: 'No food detected'
    };
  }

  // ✅ Food WAS detected! Now consume 1 HOM if user is metered
  let remainingBalance = userData.balance || 10;
  
  if (!userData.isUnlimited) {
    remainingBalance = remainingBalance - 1;
    
    await db.collection("users").doc(userId).update({
      balance: remainingBalance,
      updatedAt: admin.firestore.Timestamp.now(),
    });

    // Log HOM consumption
    await db.collection("users").doc(userId).collection("transactions").add({
      type: "consumption",
      homsConsumed: 1,
      remainingBalance: remainingBalance,
      timestamp: admin.firestore.Timestamp.now(),
    });
    
    console.log(`✅ HOMs deducted. Remaining: ${remainingBalance}`);
  }

  // Log successful processing
  await db.collection("users").doc(userId).collection("meals").add({
    ...mealAnalysis,
    processedAt: admin.firestore.Timestamp.now(),
    homsUsed: userData.isUnlimited ? 0 : 1,
    success: true,
  });

  return {
    success: true,
    analysis: mealAnalysis,
    remainingHoms: userData.isUnlimited ? "unlimited" : remainingBalance,
  };
}

/**
 * Process meal photo and return AI nutrition analysis
 * Accepts both SDK callable AND direct HTTP with Authorization header
 */
export const processMealHttp = functions.https.onRequest(
  async (req, res) => {
    // Handle CORS
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      res.status(204).send('');
      return;
    }

    // Extract token from Authorization header
    const authHeader = req.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        error: {
          code: 'unauthenticated',
          message: 'Missing or invalid Authorization header'
        }
      });
      return;
    }

    const idToken = authHeader.substring(7); // Remove 'Bearer ' prefix
    console.log('Received Authorization token: ' + idToken.substring(0, 20) + '...');

    // Verify token and get user ID
    let userId: string;
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      userId = decodedToken.uid;
      console.log('Token verified for user: ' + userId);
    } catch (tokenError: any) {
      console.error('Token verification failed:', tokenError.message);
      res.status(401).json({
        error: {
          code: 'unauthenticated',
          message: 'Invalid or expired token: ' + tokenError.message
        }
      });
      return;
    }

    try {

      // Parse request body
      // Support both SDK callable format and direct HTTP POST
      let requestData: any;
      if (req.body.data && typeof req.body.data === 'object') {
        // SDK callable format: { data: { imageBase64, ... } }
        requestData = req.body.data;
      } else {
        // Direct HTTP format: { imageBase64, ... }
        requestData = req.body;
      }

      const { imageBase64, userPreferences } = requestData;

      // Get user balance
      const userDoc = await db.collection("users").doc(userId).get();
      let userData = userDoc.data();

      if (!userData) {
        // Create user document if doesn't exist
        await db.collection("users").doc(userId).set({
          balance: 50, // 50 free HOMs for new users
          isUnlimited: false,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        });
        // Use freshly created data
        userData = {
          balance: 10,
          isUnlimited: false,
          createdAt: admin.firestore.Timestamp.now(),
          updatedAt: admin.firestore.Timestamp.now(),
        };
      }

      const result = await processMealForUser(
        userId,
        imageBase64,
        userPreferences,
        userData
      );

      res.json({
        result: result
      });
    } catch (error: any) {
      console.error("Meal processing error:", error);
      res.status(500).json({
        error: {
          code: 'internal',
          message: error.message || 'Failed to process meal'
        }
      });
    }
  }
);

/**
 * Get user's current HOM balance
 */
export const getUserBalance = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const userId = context.auth.uid;

  try {
    const userDoc = await db.collection("users").doc(userId).get();
    const userData = userDoc.data();

    if (!userData) {
      return {
        balance: 10,
        isUnlimited: false,
        isNewUser: true,
      };
    }

    return {
      balance: userData.balance || 10,
      isUnlimited: userData.isUnlimited || false,
      lastUpdated: userData.updatedAt?.toDate() || new Date(),
    };
  } catch (error) {
    console.error("Get balance error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to get balance"
    );
  }
});

/**
 * Set API key to switch to unlimited mode
 */
export const setApiKey = functions.https.onCall(
  async (data: { apiKey?: string }, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const userId = context.auth.uid;
    const { apiKey } = data;

    try {
      const userRef = db.collection("users").doc(userId);

      if (apiKey && apiKey.trim()) {
        // Validate API key format (basic check)
        if (!apiKey.startsWith("sk-")) {
          throw new functions.https.HttpsError(
            "invalid-argument",
            "Invalid API key format"
          );
        }

        // Store encrypted API key (in production, use KMS)
        await userRef.update({
          isUnlimited: true,
          apiKeyHash: hashToken(apiKey), // Store hash only
          updatedAt: admin.firestore.Timestamp.now(),
        });

        return { success: true, message: "API key set. Unlimited mode enabled." };
      } else {
        // Remove API key, revert to metered mode
        await userRef.update({
          isUnlimited: false,
          balance: 50, // Reset with free HOMs
          updatedAt: admin.firestore.Timestamp.now(),
        });

        return { success: true, message: "API key removed. Switched to metered mode." };
      }
    } catch (error: any) {
      console.error("Set API key error:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to set API key"
      );
    }
  }
);

// ============ Helper Functions ============

/**
 * Verify purchase with Google Play Billing Library
 * https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/get
 */
async function verifyGooglePlayReceipt(
  packageName: string,
  productId: string,
  purchaseToken: string
): Promise<boolean> {
  try {
    // In production, use Google Play Billing Library with service account credentials
    // For now, we'll verify the token format
    // TODO: Implement full Google Play verification with service account
    
    if (!purchaseToken || purchaseToken.length < 50) {
      return false;
    }

    // Placeholder: In production, call Google Play API
    // const response = await axios.get(
    //   `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${packageName}/purchases/products/${productId}/tokens/${purchaseToken}`,
    //   { headers: { Authorization: `Bearer ${accessToken}` } }
    // );
    // return response.data.purchaseState === 0; // 0 = purchased

    console.log(
      `Verifying purchase: package=${packageName}, product=${productId}`
    );
    return true; // For internal testing, accept valid tokens
  } catch (error) {
    console.error("Google Play verification error:", error);
    return false;
  }
}

/**
 * Analyze meal image using OpenAI Vision API
 */
async function analyzeImageWithOpenAI(
  imageBase64: string,
  preferences?: any
): Promise<any> {
  try {
    if (!OPENAI_API_KEY) {
      throw new Error("OpenAI API key not configured");
    }

    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `Analyze this meal image and identify all visible food items. For each food item, estimate the portion size and weight (WEIGHT OF FOOD ONLY, NOT INCLUDING PLATE OR BOWL) and calculate detailed nutritional information.

User preferences: ${JSON.stringify(preferences || {})}

Please respond with ONLY valid JSON in this exact format (NO MARKDOWN, NO CODE BLOCKS):

{
  "foods": [
    {
      "name": "food name",
      "description": "brief description of preparation/cooking method",
      "estimatedWeight": 150.0,
      "confidence": 0.85,
      "portionMethod": "visual estimation method used",
      "nutrition": {
        "calories": 280.0,
        "protein": 12.5,
        "carbs": 35.0,
        "fat": 8.2,
        "fiber": 3.1,
        "sugar": 2.0,
        "sodium": 450.0
      }
    }
  ]
}`,
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${imageBase64}`,
                },
              },
            ],
          },
        ],
        max_tokens: 1024,
      },
      {
        headers: {
          Authorization: `Bearer ${OPENAI_API_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    let content = response.data.choices[0].message.content;
    
    // Strip markdown code blocks if present (e.g., ```json ... ```)
    content = content.replace(/^```(json)?\n?/, '').replace(/\n?```$/, '');
    
    try {
      return JSON.parse(content);
    } catch (parseError) {
      console.warn("Failed to parse JSON response, returning as rawAnalysis:", parseError);
      return { rawAnalysis: content };
    }
  } catch (error: any) {
    console.error("OpenAI analysis error:", error.response?.data || error);
    throw new functions.https.HttpsError(
      "internal",
      "Failed to analyze meal image"
    );
  }
}

/**
 * Get HOM pack details
 */
function getHomPackDetails(productId: string): { homs: number; price: number } | null {
  const packs: { [key: string]: { homs: number; price: number } } = {
    hom_pack_10: { homs: 10, price: 2.0 },
    hom_pack_100: { homs: 100, price: 10.0 },
    hom_pack_1000: { homs: 1000, price: 50.0 },
  };

  return packs[productId] || null;
}

/**
 * Simple hash function for tokens (one-way)
 */
function hashToken(token: string): string {
  const crypto = require("crypto");
  return crypto.createHash("sha256").update(token).digest("hex");
}
