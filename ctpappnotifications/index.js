/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });



// const functions = require("firebase-functions");
// const admin = require("firebase-admin");
// admin.initializeApp();

// // Import SendGrid and Twilio libraries
// const sgMail = require("@sendgrid/mail");
// const twilio = require("twilio");

// // Set your SendGrid API key and Twilio credentials using Firebase functions config
// // Run these commands in your terminal to set the config:
// // firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
// // firebase functions:config:set twilio.sid="YOUR_TWILIO_ACCOUNT_SID" twilio.token="YOUR_TWILIO_AUTH_TOKEN"
// // firebase functions:config:set twilio.from="+YOUR_TWILIO_PHONE_NUMBER"
// sgMail.setApiKey(functions.config().sendgrid.key);

// const twilioClient = new twilio(
//   functions.config().twilio.sid,
//   functions.config().twilio.token
// );

// // Cloud Function triggered when a new offer is created
// exports.notifyTransporterOnOffer = functions.firestore
//   .document("offers/{offerId}")
//   .onCreate(async (snap, context) => {
//     const offerData = snap.data();
//     if (!offerData) return null;

//     // Extract offer details
//     const { transporterId, dealerId, vehicleId } = offerData;

//     // Fetch the transporter’s user document
//     const userDoc = await admin
//       .firestore()
//       .collection("users")
//       .doc(transporterId)
//       .get();
//     if (!userDoc.exists) {
//       console.error("Transporter user document not found");
//       return null;
//     }
//     const userData = userDoc.data();

//     // ---------- 1. Send a Push Notification (if FCM token exists) ----------
//     if (userData.fcmToken) {
//       const message = {
//         token: userData.fcmToken,
//         notification: {
//           title: "New Offer Received",
//           body: "An offer has been made on your vehicle.",
//         },
//         data: {
//           offerId: context.params.offerId,
//           vehicleId: vehicleId,
//         },
//       };
//       try {
//         await admin.messaging().send(message);
//         console.log("Push notification sent to transporter.");
//       } catch (error) {
//         console.error("Error sending push notification:", error);
//       }
//     } else {
//       console.log("No FCM token found for transporter.");
//     }

//     // ---------- 2. Send an Email Notification via SendGrid ----------
//     if (userData.email) {
//       const emailMsg = {
//         to: userData.email,
//         from: "noreply@yctpapp.co.za", // Use a verified sender email address
//         subject: "New Offer on Your Vehicle",
//         text: "A new offer has been made on your vehicle. Please check your account for details.",
//         html: "<p>A new offer has been made on your vehicle. Please check your account for details.</p>",
//       };
//       try {
//         await sgMail.send(emailMsg);
//         console.log("Email notification sent to transporter.");
//       } catch (error) {
//         console.error("Error sending email notification:", error);
//       }
//     }

//     // ---------- 3. Send an SMS Notification via Twilio ----------
//     if (userData.phoneNumber) {
//       try {
//         await twilioClient.messages.create({
//           body: "A new offer has been made on your vehicle. Please check your account for details.",
//           from: functions.config().twilio.from,
//           to: userData.phoneNumber,
//         });
//         console.log("SMS notification sent to transporter.");
//       } catch (error) {
//         console.error("Error sending SMS notification:", error);
//       }
//     }

//     return null;
//   });
