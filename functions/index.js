const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

// Import Places API functions
const placesApi = require("./src/places-api");

// Export all places API functions
exports.placesAutocomplete = placesApi.placesAutocomplete;
exports.getPlaceDetails = placesApi.getPlaceDetails;

admin.initializeApp();
const db = admin.firestore();

const express = require('express');
const { onRequest } = require('firebase-functions/v2/https');
const app = express();

// Existing function for offer notifications
exports.sendOfferNotification = onDocumentCreated(
  {
    document: "offers/{offerId}",
    region: "europe-west3", // Update to match your desired region
  },
  async (event) => {
    const snap = event.data;
    const offerData = snap.data();

    // Get the transporter ID and other offer details
    const transporterId = offerData.transporterId;
    const offerAmount = offerData.offerAmount;
    const vehicleId = offerData.vehicleId;

    // Fetch the transporter's FCM token from Firestore
    const transporterDoc = await db
      .collection("users")
      .doc(transporterId)
      .get();

    if (!transporterDoc.exists) {
      console.log("No such transporter user found");
      return;
    }

    const fcmToken = transporterDoc.data().fcmToken;

    // If the transporter has an FCM token, send the notification
    if (fcmToken) {
      const payload = {
        notification: {
          title: "New Offer on Your Vehicle",
          body: `A dealer has made an offer of R${offerAmount} on your vehicle.`,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          vehicleId: vehicleId,
          offerId: event.params.offerId,
        },
      };

      try {
        await admin.messaging().sendToDevice(fcmToken, payload);
        console.log("Notification sent to transporter:", transporterId);
      } catch (error) {
        console.error("Error sending notification:", error);
      }
    } else {
      console.log("Transporter does not have an FCM token");
    }
  }
);

// New function to notify admins when a new user is created
exports.notifyAdminsOnNewUser = onDocumentCreated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const userData = snap.data();
    const userId = event.params.userId;

    // Only notify for dealer, transporter, or pending registrations
    if (
      !userData.userRole ||
      (userData.userRole !== "dealer" &&
        userData.userRole !== "transporter" &&
        userData.userRole !== "pending")
    ) {
      console.log(
        "Skipping notification for non-dealer/transporter/pending user"
      );
      return;
    }

    console.log(
      `New ${userData.userRole} registered: ${userData.firstName} ${userData.lastName}`
    );

    try {
      // Get all admin users
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log("No admin users found to notify");
        return;
      }

      const companyName = userData.companyName || "N/A";
      const userFullName =
        `${userData.firstName || ""} ${userData.lastName || ""}`.trim() ||
        "New user";

      // Send notification to each admin using admin.messaging().send(...)
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();

        if (!adminData.fcmToken) {
          console.log(`Admin ${adminDoc.id} has no FCM token`);
          continue;
        }

        const message = {
          notification: {
            title: `New ${userData.userRole} Registration`,
            body: `${userFullName} from ${companyName} has registered as a ${userData.userRole}.`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            userId: userId,
            notificationType: "new_user_registration",
            userRole: userData.userRole,
            timestamp: new Date().toISOString(),
          },
          token: adminData.fcmToken,
        };

        try {
          await admin.messaging().send(message);
          console.log(`Notification sent to admin ${adminDoc.id}`);
        } catch (error) {
          console.error(
            `Error sending notification to admin ${adminDoc.id}:`,
            error
          );
        }
      }

      console.log("Admin notifications process completed");
    } catch (error) {
      console.error("Error in notifyAdminsOnNewUser function:", error);
    }
  }
);

// Send a notification to dealers when a new vehicle is posted or status changes to "live"
exports.notifyDealersOnNewVehicle = onDocumentCreated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const vehicleData = snap.data();
    const vehicleId = event.params.vehicleId;

    // Only notify for vehicles with "live" status
    if (
      vehicleData.vehicleStatus &&
      vehicleData.vehicleStatus.toLowerCase() === "live"
    ) {
      console.log(
        `New live vehicle posted: ${vehicleData.brand} ${vehicleData.model}`
      );

      try {
        // Send notification to "newVehicles" topic (all dealers should be subscribed)
        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${vehicleData.brand} ${vehicleData.model} ${vehicleData.year} is now available.`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: vehicleData.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };

        await admin.messaging().send(message);
        console.log(
          "Notification sent to all dealers subscribed to newVehicles topic"
        );
      } catch (error) {
        console.error("Error sending new vehicle notification:", error);
      }
    } else {
      console.log("Vehicle not live, no notification sent");
    }
  }
);

// Direct notification function (callable from client for testing)
exports.sendDirectNotification = require("firebase-functions/v2/https").onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const { userId, title, body, data = {} } = request.data;

    if (!userId || !title || !body) {
      throw new Error(
        "Missing required parameters: userId, title, and body are required"
      );
    }

    try {
      // Get user's FCM token
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new Error("User not found");
      }

      const userData = userDoc.data();
      if (!userData.fcmToken) {
        throw new Error("User has no FCM token registered");
      }

      // Send notification
      const message = {
        notification: {
          title: title,
          body: body,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
        data: {
          ...data,
          timestamp: new Date().toISOString(),
        },
        token: userData.fcmToken,
      };

      await admin.messaging().send(message);
      return { success: true, message: "Notification sent successfully" };
    } catch (error) {
      console.error("Error sending direct notification:", error);
      throw new Error(`Failed to send notification: ${error.message}`);
    }
  }
);

// Additional specific notification for new vehicles
exports.sendNewVehicleNotification =
  require("firebase-functions/v2/https").onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      const { vehicleId } = request.data;

      if (!vehicleId) {
        throw new Error("Missing required parameter: vehicleId");
      }

      try {
        // Get vehicle data
        const vehicleDoc = await db.collection("vehicles").doc(vehicleId).get();

        if (!vehicleDoc.exists) {
          throw new Error("Vehicle not found");
        }

        const vehicleData = vehicleDoc.data();

        // Send notification to all dealers through the topic
        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${vehicleData.brand} ${vehicleData.model} ${
              vehicleData.year || ""
            } is now available.`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: vehicleData.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };

        await admin.messaging().send(message);
        return {
          success: true,
          message: "New vehicle notification sent to all dealers",
        };
      } catch (error) {
        console.error("Error sending new vehicle notification:", error);
        throw new Error(`Failed to send notification: ${error.message}`);
      }
    }
  );

// Special test function that doesn't require App Check
exports.sendDirectNotificationNoAppCheck =
  require("firebase-functions/v2/https").onCall(
    {
      region: "us-central1",
      enforceAppCheck: false, // Explicitly disable App Check for this function
    },
    async (request) => {
      const { userId, title, body, dataPayload = {} } = request.data;

      if (!userId || !title || !body) {
        throw new Error(
          "Missing required parameters: userId, title, and body are required"
        );
      }

      try {
        console.log(`Attempting to send test notification to user ${userId}`);

        // Get user's FCM token
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists) {
          throw new Error("User not found");
        }

        const userData = userDoc.data();
        if (!userData.fcmToken) {
          throw new Error("User has no FCM token registered");
        }

        console.log(
          `Found FCM token for user: ${userData.fcmToken.substring(0, 20)}...`
        );

        // Send notification
        const message = {
          notification: {
            title: title,
            body: body,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            ...dataPayload,
            timestamp: new Date().toISOString(),
            isTestNotification: "true",
          },
          token: userData.fcmToken,
        };

        await admin.messaging().send(message);
        console.log("Test notification sent successfully");

        return {
          success: true,
          message: "Test notification sent successfully",
          timestamp: new Date().toISOString(),
        };
      } catch (error) {
        console.error("Error sending test notification:", error);
        throw new Error(`Failed to send test notification: ${error.message}`);
      }
    }
  );

// Dynamic SSR for vehicle link previews
app.get('/vehicle/:id', async (req, res) => {
  try {
    const snap = await db.collection('vehicles').doc(req.params.id).get();
    if (!snap.exists) return res.status(404).send('Vehicle not found');
    const v = snap.data();
    const title = `${v.manokeModel} • R${v.expectedSellingPrice}`;
    const desc  = `${v.year} • ${v.mileage} km • ${v.transmission} • Accidents: ${v.accidentFree ? 'None' : 'Yes'}`;
    const img   = v.mainImageUrl;
    const url   = `https://ctpapp.co.za/vehicle/${req.params.id}`;
    res.set('Cache-Control', 'public, max-age=300');
    return res.send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${title}</title>
  <meta property="og:title" content="${title}" />
  <meta property="og:description" content="${desc}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:url" content="${url}" />
  <meta name="twitter:card" content="summary_large_image" />
  <script defer src="/main.dart.js"></script>
</head>
<body></body>
</html>`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Internal error');
  }
});

// Export Express app for hosting /vehicle/* SSR
exports.app = onRequest({ region: 'us-central1' }, app);
