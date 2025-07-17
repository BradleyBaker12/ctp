// Load environment variables from .env
require("dotenv").config();
const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const functions = require("firebase-functions");
const sgMail = require("@sendgrid/mail");
// Initialize SendGrid API key, preferring env var, then config(), with safety check
const sgKey =
  process.env.SENDGRID_API_KEY ||
  (functions.config().sendgrid && functions.config().sendgrid.key);
if (!sgKey) {
  console.warn(
    "Warning: No SendGrid API key found in process.env.SENDGRID_API_KEY or functions.config().sendgrid.key"
  );
} else {
  sgMail.setApiKey(sgKey);
}

// Import Places API functions
const placesApi = require("./src/places-api");

// Import HTTP trigger helper for v2 functions
const { onRequest } = require("firebase-functions/v2/https");

// Export all places API functions as HTTP triggers in europe-west3
exports.placesAutocomplete = onRequest(
  { region: "europe-west3" },
  placesApi.placesAutocomplete
);
exports.getPlaceDetails = onRequest(
  { region: "europe-west3" },
  placesApi.getPlaceDetails
);

admin.initializeApp();
const db = admin.firestore();

const express = require("express");
const app = express();

// Existing function for offer notifications
// exports.sendOfferNotification = onDocumentCreated(
//   {
//     document: "offers/{offerId}",
//     region: "europe-west3", // Update to match your desired region
//   },
//   async (event) => {
//     const snap = event.data;
//     const offerData = snap.data();

//     // Get the transporter ID and other offer details
//     const transporterId = offerData.transporterId;
//     const offerAmount = offerData.offerAmount;
//     const vehicleId = offerData.vehicleId;

//     // Fetch the transporter's FCM token from Firestore
//     const transporterDoc = await db
//       .collection("users")
//       .doc(transporterId)
//       .get();

//     if (!transporterDoc.exists) {
//       console.log("No such transporter user found");
//       return;
//     }

//     const fcmToken = transporterDoc.data().fcmToken;

//     // If the transporter has an FCM token, send the notification
//     if (fcmToken) {
//       const payload = {
//         notification: {
//           title: "New Offer on Your Vehicle",
//           body: `A dealer has made an offer of R${offerAmount} on your vehicle.`,
//           clickAction: "FLUTTER_NOTIFICATION_CLICK",
//         },
//         data: {
//           vehicleId: vehicleId,
//           offerId: event.params.offerId,
//         },
//       };

//       try {
//         await admin.messaging().sendToDevice(fcmToken, payload);
//         console.log("Notification sent to transporter:", transporterId);
//       } catch (error) {
//         console.error("Error sending notification:", error);
//       }
//     } else {
//       console.log("Transporter does not have an FCM token");
//     }
//   }
// );

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

// Notify dealers and admins when a vehicle is created or updated (live or pending)
exports.notifyDealersAndAdminsOnVehicleChange = onDocumentCreated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealersAndAdminsOnVehicleChange] Triggered for vehicleId:",
      event.params.vehicleId
    );
    const snap = event.data;
    if (!snap) {
      console.log("[notifyDealersAndAdminsOnVehicleChange] No snapshot data");
      return;
    }
    const vehicleData = snap.data();
    const vehicleId = event.params.vehicleId;
    console.log(
      "[notifyDealersAndAdminsOnVehicleChange] vehicleData:",
      vehicleData
    );

    // Notify dealers if live
    if (
      vehicleData.vehicleStatus &&
      vehicleData.vehicleStatus.toLowerCase() === "live"
    ) {
      try {
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
        console.log(
          "[notifyDealersAndAdminsOnVehicleChange] Sending FCM topic message:",
          message
        );
        await admin.messaging().send(message);
        console.log(
          "Notification sent to all dealers subscribed to newVehicles topic"
        );
      } catch (error) {
        console.error("Error sending new vehicle notification:", error);
      }
    }

    // Notify admins if pending
    if (
      vehicleData.vehicleStatus &&
      vehicleData.vehicleStatus.toLowerCase() === "pending"
    ) {
      try {
        // Send push notification to all admins
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        console.log(
          `[notifyDealersAndAdminsOnVehicleChange] Found ${adminUsersSnapshot.size} admin users`
        );
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();
          if (!adminData.fcmToken) {
            console.log(
              `[notifyDealersAndAdminsOnVehicleChange] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }
          const message = {
            notification: {
              title: "Vehicle Pending Approval",
              body:
                "A vehicle (" +
                (vehicleData.brand || "") +
                " " +
                (vehicleData.model || "") +
                ") is pending admin approval.",
              // clickAction: "FLUTTER_NOTIFICATION_CLICK", // REMOVED for FCM v2 compatibility
            },
            data: {
              vehicleId: vehicleId,
              notificationType: "vehicle_pending_approval",
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };
          console.log(
            `[notifyDealersAndAdminsOnVehicleChange] Sending FCM to admin ${adminDoc.id}:`,
            message
          );
          try {
            await admin.messaging().send(message);
            console.log(
              `[notifyDealersAndAdminsOnVehicleChange] Notification sent to admin ${adminDoc.id}`
            );
          } catch (err) {
            console.error(
              "Error sending pending approval notification to admin " +
                adminDoc.id +
                ":",
              err
            );
          }
        }
        // Send email to all admin users via SendGrid
        const adminEmailSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminEmails = adminEmailSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);
        if (adminEmails.length > 0) {
          const today = new Date().toLocaleDateString();
          // Fetch user’s name and company for email template
          const transporterDoc = await db
            .collection("users")
            .doc(vehicleData.userId)
            .get();
          let transporterName = "N/A";
          if (transporterDoc.exists) {
            const data = transporterDoc.data();
            transporterName = `${data.firstName || ""} ${
              data.lastName || ""
            }`.trim();
            if (data.companyName) {
              transporterName += ` from ${data.companyName}`;
            }
          }
          // Use SendGrid dynamic template for pending approval
          const emailMsg = {
            to: adminEmails, // send to all admin email addresses
            from: "admin@ctpapp.co.za",
            templateId: process.env.SENDGRID_TEMPLATE_ID.trim(),
            dynamic_template_data: {
              // pull brand from the first element of your brands array (or fallback)
              brand:
                vehicleData.brands?.[0] ||
                vehicleData.modelDetails?.manufacturer ||
                "N/A",

              // model lives under modelDetails.model or makeModel
              model:
                vehicleData.modelDetails?.model ||
                vehicleData.makeModel ||
                "N/A",

              // you already have variant at top level
              variant: vehicleData.variant || "N/A",

              // year is either nested or top-level
              year: vehicleData.modelDetails?.year || vehicleData.year || "N/A",

              // transporter full name for template
              transporter: transporterName,

              date: today,

              vehicleLink: `https://ctpapp.co.za/vehicle/${vehicleId}`,
              content: `A new vehicle (${
                vehicleData.brands?.[0] ||
                vehicleData.modelDetails?.manufacturer ||
                "N/A"
              } ${
                vehicleData.modelDetails?.model ||
                vehicleData.makeModel ||
                "N/A"
              }, ${
                vehicleData.modelDetails?.year || vehicleData.year || "N/A"
              }) is pending approval.`,
              // THIS WAS MISSING — must match {{imageUrl}}
              imageUrl: vehicleData.mainImageUrl || "",
            },
          };
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] Sending SendGrid dynamic template email"
          );
          await sgMail.send(emailMsg);
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] SendGrid dynamic template email sent"
          );
        } else {
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] No admin emails found for SendGrid"
          );
        }
      } catch (error) {
        console.error(
          "Error in notifyDealersAndAdminsOnVehicleChange function (pending):",
          error
        );
      }
    }
  }
);

exports.notifyDealersAndAdminsOnVehicleChangeUpdate = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealersAndAdminsOnVehicleChangeUpdate] Triggered for vehicleId:",
      event.params.vehicleId
    );
    const before = event.data.before.data();
    const after = event.data.after.data();
    const vehicleId = event.params.vehicleId;
    if (!before || !after) {
      console.log(
        "[notifyDealersAndAdminsOnVehicleChangeUpdate] No before/after data"
      );
      return;
    }
    console.log(
      "[notifyDealersAndAdminsOnVehicleChangeUpdate] before:",
      before
    );
    console.log("[notifyDealersAndAdminsOnVehicleChangeUpdate] after:", after);
    // Notify dealers if status changed to live
    if (
      before.vehicleStatus !== "live" &&
      after.vehicleStatus &&
      after.vehicleStatus.toLowerCase() === "live"
    ) {
      try {
        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${after.brand} ${after.model} ${
              after.year || ""
            } is now available.`,
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: after.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };
        console.log(
          "[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending FCM topic message:",
          message
        );
        await admin.messaging().send(message);
        console.log(
          "[UPDATE] Notification sent to all dealers subscribed to newVehicles topic"
        );
      } catch (error) {
        console.error(
          "[UPDATE] Error sending new vehicle notification:",
          error
        );
      }
    }
    // Notify admins if status changed to pending
    if (
      before.vehicleStatus !== "pending" &&
      after.vehicleStatus &&
      after.vehicleStatus.toLowerCase() === "pending"
    ) {
      try {
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        console.log(
          `[notifyDealersAndAdminsOnVehicleChangeUpdate] Found ${adminUsersSnapshot.size} admin users`
        );
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();
          if (!adminData.fcmToken) {
            console.log(
              `[notifyDealersAndAdminsOnVehicleChangeUpdate] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }
          const message = {
            notification: {
              title: "Vehicle Pending Approval",
              body:
                "A vehicle " +
                (after.brands?.[0] || after.modelDetails?.manufacturer || "") +
                " " +
                (after.makeModel || after.modelDetails?.model || "") +
                " is pending admin approval.",
              // clickAction removed for FCM v2 compatibility
            },
            data: {
              vehicleId: vehicleId,
              notificationType: "vehicle_pending_approval",
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };
          console.log(
            `[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending FCM to admin ${adminDoc.id}:`,
            message
          );
          try {
            await admin.messaging().send(message);
            console.log(
              `[notifyDealersAndAdminsOnVehicleChangeUpdate] Notification sent to admin ${adminDoc.id}`
            );
          } catch (err) {
            console.error(
              "[UPDATE] Error sending pending approval notification to admin " +
                adminDoc.id +
                ":",
              err
            );
          }
        }
        // Send email to all admin users via SendGrid
        const adminEmailSnapshot2 = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminEmails2 = adminEmailSnapshot2.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);
        if (adminEmails2.length > 0) {
          const today = new Date().toLocaleDateString();
          // Safely fetch user’s name and company for email template update
          let transporterName = "N/A";
          if (after.userId) {
            const docRef = db.collection("users").doc(after.userId);
            const transporterDoc = await docRef.get();
            if (transporterDoc.exists) {
              const data = transporterDoc.data();
              transporterName =
                `${data.firstName || ""} ${data.lastName || ""}`.trim() ||
                "N/A";
              if (data.companyName) {
                transporterName += ` from ${data.companyName}`;
              }
            }
          }
          // Use SendGrid dynamic template for pending approval update
          const emailMsg2 = {
            to: adminEmails2, // send update emails to all admin addresses
            from: "admin@ctpapp.co.za",
            templateId: process.env.SENDGRID_TEMPLATE_ID.trim(), // updated for v2 compatibility
            dynamic_template_data: {
              brand:
                Array.isArray(after.brands) && after.brands.length > 0
                  ? after.brands[0]
                  : "N/A",
              model: after.makeModel || "N/A",
              variant: after.variant || "N/A",
              year: after.year || "N/A",
              transporter: transporterName,
              date: today,
              vehicleLink: `https://ctpapp.co.za/vehicle/${vehicleId}`,
              content: `A new vehicle (${
                Array.isArray(after.brands) && after.brands.length > 0
                  ? after.brands[0]
                  : "N/A"
              } ${after.makeModel || "N/A"}, ${
                after.year || "N/A"
              }) is pending approval.`,
              imageUrl: after.mainImageUrl || "", // renamed to match {{imageUrl}} in template
            },
          };
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending SendGrid dynamic template email"
          );
          await sgMail.send(emailMsg2);
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] SendGrid dynamic template email sent"
          );
        } else {
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] No admin emails found for SendGrid"
          );
        }
      } catch (error) {
        if (
          error.response &&
          error.response.body &&
          error.response.body.errors
        ) {
          console.error(
            "[UPDATE] SendGrid payload errors:",
            error.response.body.errors
          );
        } else {
          console.error(
            "[UPDATE] Unexpected error in notifyDealersAndAdminsOnVehicleChangeUpdate:",
            error
          );
        }
      }
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
app.get("/vehicle/:id", async (req, res) => {
  try {
    const snap = await db.collection("vehicles").doc(req.params.id).get();
    if (!snap.exists) return res.status(404).send("Vehicle not found");
    const v = snap.data();
    const title = `${v.manokeModel} • R${v.expectedSellingPrice}`;
    const desc = `${v.year} • ${v.mileage} km • ${
      v.transmission
    } • Accidents: ${v.accidentFree ? "None" : "Yes"}`;
    const img = v.mainImageUrl;
    const url = `https://ctpapp.co.za/vehicle/${req.params.id}`;
    res.set("Cache-Control", "public, max-age=300");
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
    res.status(500).send("Internal error");
  }
});

// Export Express app for hosting /vehicle/* SSR
exports.app = onRequest({ region: "us-central1" }, app);

// Test SendGrid integration endpoint
exports.testSendGridIntegration = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    try {
      await sgMail.send({
        to: "bradley@reagency.co.za",
        from: "admin@ctpapp.co.za",
        subject: "🚀 SendGrid Integration OK",
        text: "If you see this, SendGrid is live in your Functions!",
      });
      console.log("SendGrid test email sent");
      res.send("✅ Sent");
    } catch (e) {
      console.error("SendGrid test failed:", e);
      res.status(500).send(`❌ Error: ${e.message}`);
    }
  }
);

// Email notification on vehicle approval
exports.onVehicleApproved = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const context = event; // for param access

    // Capture and normalize status values with trimming
    const rawBeforeStatus = before.vehicleStatus || before.status || "";
    const rawAfterStatus = after.vehicleStatus || after.status || "";
    console.log(
      `[onVehicleApproved] Raw statuses for vehicle ${context.params.vehicleId}: before.vehicleStatus="${rawBeforeStatus}", before.status="${before.status}", after.vehicleStatus="${rawAfterStatus}", after.status="${after.status}"`
    );
    const beforeStatus = rawBeforeStatus.toLowerCase().trim();
    const afterStatus = rawAfterStatus.toLowerCase().trim();
    console.log(
      `[onVehicleApproved] Condition check for vehicle ${context.params.vehicleId}: ` +
        `beforeStatus!=="approved"=${beforeStatus !== "approved"}, ` +
        `afterStatus==="approved"=${afterStatus === "approved"}, ` +
        `beforeStatus!=="live"=${beforeStatus !== "live"}, ` +
        `afterStatus==="live"=${afterStatus === "live"}`
    );
    if (
      (beforeStatus !== "approved" && afterStatus === "approved") ||
      (beforeStatus !== "live" && afterStatus === "live")
    ) {
      console.log(
        `[onVehicleApproved] Triggered for vehicle ${context.params.vehicleId}, status changed from ${beforeStatus} to ${afterStatus}`
      );
      // 1. Fetch transporter email from users collection using userId
      let transporterEmail = null;
      let transporterName = "";
      if (after.userId) {
        try {
          const transporterDoc = await db
            .collection("users")
            .doc(after.userId)
            .get();
          if (transporterDoc.exists) {
            const transporterData = transporterDoc.data();
            transporterEmail = transporterData.email || null;
            transporterName = `${transporterData.firstName || ""} ${
              transporterData.lastName || ""
            }`.trim();
          } else {
            console.warn(
              "Transporter user not found for userId:",
              after.userId
            );
          }
        } catch (err) {
          console.error(
            "Error fetching transporter user for vehicle",
            context.params.vehicleId,
            err
          );
        }
      } else {
        console.warn(
          "No userId found on vehicle for transporter lookup",
          context.params.vehicleId
        );
      }
      const make = after.make || after.brands?.[0] || "";
      const model =
        after.model || after.makeModel || after.modelDetails?.model || "";
      const year = after.year || after.modelDetails?.year || "";
      const variant = after.variant || "";
      const vehicleLink = `https://ctpapp.co.za/vehicle/${context.params.vehicleId}`;
      const imageUrl = after.mainImageUrl || "";

      // Send dynamic template email to transporter (test: only send to bradley@reagency.co.za)
      if (transporterEmail) {
        try {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: "bradley@reagency.co.za", // TEST: force all transporter emails to Bradley
            templateId: process.env.SENDGRID_TRANSPORTER_TEMPLATE_ID.trim(),
            dynamic_template_data: {
              make,
              model,
              year,
              variant,
              transporter: transporterName,
              vehicleLink,
              imageUrl,
            },
          });
        } catch (err) {
          console.error("Error sending approval email to transporter:", err);
        }
      } else {
        console.warn(
          "No transporter email found for vehicle",
          context.params.vehicleId
        );
      }

      // 2. Notify all dealers with dynamic template (test: only send to bradley@reagency.co.za)
      try {
        await sgMail.send({
          from: "admin@ctpapp.co.za",
          to: "bradley@reagency.co.za", // TEST: force all dealer emails to Bradley
          templateId: process.env.SENDGRID_DEALER_TEMPLATE_ID.trim(),
          dynamic_template_data: {
            make,
            model,
            year,
            variant,
            vehicleLink,
            imageUrl,
          },
        });
      } catch (err) {
        console.error("Error sending new vehicle email to dealers:", err);
      }

      // Send push notification to transporter (using their actual FCM token)
      if (transporterEmail) {
        try {
          // Fetch transporter FCM token
          let transporterFcmToken = null;
          if (after.userId) {
            const transporterDoc = await db
              .collection("users")
              .doc(after.userId)
              .get();
            if (transporterDoc.exists) {
              const transporterData = transporterDoc.data();
              transporterFcmToken = transporterData.fcmToken || null;
            }
          }
          if (transporterFcmToken) {
            await admin.messaging().send({
              notification: {
                title: "Your vehicle has been approved!",
                body: `Congratulations! Your vehicle ${make} ${model} is now live on the platform.`,
              },
              token: transporterFcmToken,
            });
          } else {
            console.warn("No FCM token found for transporter", after.userId);
          }
        } catch (err) {
          console.error("Error sending push notification to transporter:", err);
        }
      }

      // Send push notification to all dealers (using their FCM tokens)
      try {
        // Fetch all dealer FCM tokens
        const dealersSnapshot = await db
          .collection("users")
          .where("userRole", "==", "dealer")
          .get();
        const dealerFcmTokens = dealersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => !!token);
        if (dealerFcmTokens.length > 0) {
          // FCM allows up to 500 tokens per sendMulticast
          const batchSize = 500;
          for (let i = 0; i < dealerFcmTokens.length; i += batchSize) {
            const batchTokens = dealerFcmTokens.slice(i, i + batchSize);
            await admin.messaging().sendMulticast({
              notification: {
                title: "New Vehicles Listed!",
                body: "There are new vehicles that have been listed. Come check it out!",
              },
              tokens: batchTokens,
            });
          }
        } else {
          console.warn("No dealer FCM tokens found for push notification");
        }
      } catch (err) {
        console.error("Error sending push notification to dealers:", err);
      }
    }
    return null;
  }
);

// Notify admins when a dealer or transporter completes registration (i.e., phone number is set)
exports.notifyAdminsOnUserPhoneAdded = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const userId = event.params.userId;
    if (!before || !after) return;

    // Only trigger for dealer or transporter
    const userRole = after.userRole;
    if (userRole !== "dealer" && userRole !== "transporter") return;

    // Only trigger if phoneNumber was previously missing and is now set
    const beforePhone = before.phoneNumber || before.phone || null;
    const afterPhone = after.phoneNumber || after.phone || null;
    // Required fields for registration completion
    const requiredFields = [
      "companyName",
      "firstName",
      "lastName",
      "addressLine1",
      "city",
      "state",
      "postalCode",
      "country",
      "phoneNumber",
    ];
    // Check if all required fields are present and non-empty in 'after'
    const registrationComplete = requiredFields.every(
      (field) => after[field] && String(after[field]).trim() !== ""
    );
    if (!beforePhone && afterPhone && registrationComplete) {
      // Send push notification to all admins
      try {
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminFcmTokens = adminUsersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => !!token);
        if (adminFcmTokens.length === 0) {
          console.warn(
            "No admin FCM tokens found for registration notification"
          );
        } else {
          for (const token of adminFcmTokens) {
            try {
              await admin.messaging().send({
                notification: {
                  title: `New ${userRole} Registration Completed`,
                  body: `A ${userRole} has completed registration. Phone: ${afterPhone}`,
                },
                token: token,
              });
              console.log(`Notification sent to admin FCM token ${token}`);
            } catch (pushErr) {
              console.error(
                "Error sending push notification to admin:",
                pushErr
              );
            }
          }
        }
      } catch (err) {
        console.error("Error fetching admin users for push notification:", err);
      }
      return;
    }

    // Fetch admin emails
    /*
    const adminSnapshot = await db
      .collection("users")
      .where("userRole", "in", ["admin", "sales representative"])
      .get();
    const adminEmails = adminSnapshot.docs
      .map((doc) => doc.data().email)
      .filter((email) => !!email);
    if (adminEmails.length === 0) {
      console.warn("No admin emails found for registration notification");
      return;
    }
    // Compose email
    const name = `${after.firstName || ""} ${after.lastName || ""}`.trim();
    const company = after.companyName || after.tradingName || "";
    const email = after.email || "";
    const role = userRole.charAt(0).toUpperCase() + userRole.slice(1);
    try {
      await sgMail.send({
        from: "admin@ctpapp.co.za",
        to: adminEmails,
        subject: `New ${role} Registration Completed`,
        text: `${role} ${name} (${email}) from ${company} has completed registration. Phone: ${afterPhone}`,
        html: `<p><b>${role} Registration Completed</b></p><p>Name: ${name}<br>Email: ${email}<br>Company: ${company}<br>Phone: ${afterPhone}</p>`,
      });
      console.log(
        `Admin notified of new ${role} registration for userId ${userId}`
      );
    } catch (err) {
      console.error("Error sending admin registration notification:", err);
    }
    */
  }
);
