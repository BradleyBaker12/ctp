const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

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
