import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const sendNewVehicleNotification = functions.https.onCall(
  async (request: functions.https.CallableRequest<any>) => {
    const { vehicleId } = request.data;

    try {
      const vehicleSnap = await admin
        .firestore()
        .collection("vehicles")
        .doc(vehicleId)
        .get();
      const vehicleData = vehicleSnap.data();

      if (!vehicleData) return;

      const message = {
        notification: {
          title: "New Vehicle Available",
          body: `A new ${vehicleData.brand} ${vehicleData.model} is now available`,
        },
        topic: "newVehicles",
      };

      await admin.messaging().send(message);
    } catch (error) {
      console.error("Error sending notification:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification"
      );
    }
  }
);
