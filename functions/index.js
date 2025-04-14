const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onCall, onRequest } = require("firebase-functions/v2/https");

// Import Places API functions
const placesApi = require("./src/places-api");

// Export all places API functions
exports.placesAutocomplete = placesApi.placesAutocomplete;
exports.getPlaceDetails = placesApi.getPlaceDetails;

initializeApp();
const db = getFirestore();

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
        await getMessaging().sendToDevice(fcmToken, payload);
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

    // Only notify for dealer or transporter registrations
    if (
      !userData.userRole ||
      (userData.userRole !== "dealer" && userData.userRole !== "transporter")
    ) {
      console.log("Skipping notification for non-dealer/transporter user");
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

      // Send notification to each admin
      const notifications = adminUsersSnapshot.docs.map(async (adminDoc) => {
        const adminData = adminDoc.data();

        if (!adminData.fcmToken) {
          console.log(`Admin ${adminDoc.id} has no FCM token`);
          return;
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
          await getMessaging().send(message);
          console.log(`Notification sent to admin ${adminDoc.id}`);
          return true;
        } catch (error) {
          console.error(
            `Error sending notification to admin ${adminDoc.id}:`,
            error
          );
          return false;
        }
      });

      await Promise.all(notifications);
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

        await getMessaging().send(message);
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
exports.sendDirectNotification = onCall(
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

      await getMessaging().send(message);
      return { success: true, message: "Notification sent successfully" };
    } catch (error) {
      console.error("Error sending direct notification:", error);
      throw new Error(`Failed to send notification: ${error.message}`);
    }
  }
);

// Additional specific notification for new vehicles
exports.sendNewVehicleNotification = onCall(
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

      await getMessaging().send(message);
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
