import * as functions from "firebase-functions/v2";
import * as functionsV1 from "firebase-functions";
import * as admin from "firebase-admin";
import fetch from "node-fetch";

admin.initializeApp();

// Places Autocomplete API for location search
export const placesAutocomplete = functions.https.onRequest(
  {
    region: "europe-west3",
    cors: true,
    maxInstances: 10,
  },
  async (req, res) => {
    try {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, POST");
      res.set("Access-Control-Allow-Headers", "Content-Type");

      // Handle preflight OPTIONS request
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      console.log(
        "placesAutocomplete function called with input:",
        req.query.input
      );

      // Get the input query parameter from the request
      const input = req.query.input;

      if (!input || typeof input !== "string") {
        res.status(400).json({
          error: "Missing or invalid input parameter",
        });
        return;
      }

      // Get the API key from environment variables
      const apiKey = process.env.GOOGLE_PLACES_API_KEY;

      if (!apiKey) {
        console.error("Google Places API key is not configured");
        res.status(500).json({
          error: "Server configuration error: Missing API key",
        });
        return;
      }

      console.log(`Fetching places suggestions for query: "${input}"`);

      // Construct the Google Places API URL
      const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(
        input
      )}&key=${apiKey}`;

      // Make the request to Google Places API
      const response = await fetch(url);
      const data = await response.json();

      console.log(
        `Received ${data.predictions?.length || 0} predictions from Places API`
      );

      // Return the response
      res.status(200).json(data);
      return;
    } catch (error) {
      console.error("Error in placesAutocomplete function:", error);
      res.status(500).json({
        error: "An error occurred while processing your request",
        details: error instanceof Error ? error.message : "Unknown error",
      });
      return;
    }
  }
);

// Get place details including lat/lng coordinates for a place ID
export const getPlaceDetails = functions.https.onRequest(
  {
    region: "europe-west3",
    cors: true,
    maxInstances: 10,
  },
  async (req, res) => {
    try {
      // Set CORS headers
      res.set("Access-Control-Allow-Origin", "*");
      res.set("Access-Control-Allow-Methods", "GET, POST");
      res.set("Access-Control-Allow-Headers", "Content-Type");

      // Handle preflight OPTIONS request
      if (req.method === "OPTIONS") {
        res.status(204).send("");
        return;
      }

      // Get the placeId parameter from the request
      const placeId = req.query.placeId;

      if (!placeId || typeof placeId !== "string") {
        res.status(400).json({
          error: "Missing or invalid placeId parameter",
        });
        return;
      }

      // Get the API key from environment variables
      const apiKey = process.env.GOOGLE_PLACES_API_KEY;

      if (!apiKey) {
        console.error("Google Places API key is not configured");
        res.status(500).json({
          error: "Server configuration error: Missing API key",
        });
        return;
      }

      console.log(`Fetching details for place ID: "${placeId}"`);

      // Construct the Google Places API URL for place details
      const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&fields=address_component,geometry,formatted_address&key=${apiKey}`;

      // Make the request to Google Places API
      const response = await fetch(url);
      const data = await response.json();

      // If the request was successful and we have results
      if (data.status === "OK" && data.result) {
        // Extract the important details we need
        const result = {
          lat: data.result.geometry?.location?.lat,
          lng: data.result.geometry?.location?.lng,
          formattedAddress: data.result.formatted_address,
          city: "",
          state: "",
          postalCode: "",
        };

        // Parse address components to get city, state, postal code
        if (data.result.address_components) {
          for (const component of data.result.address_components) {
            if (component.types.includes("locality")) {
              result.city = component.long_name;
            } else if (
              component.types.includes("administrative_area_level_1")
            ) {
              result.state = component.long_name;
            } else if (component.types.includes("postal_code")) {
              result.postalCode = component.long_name;
            }
          }
        }

        console.log(
          `Successfully retrieved details for place ID: "${placeId}"`
        );
        res.status(200).json(result);
        return;
      } else {
        console.error(`Failed to get place details: ${data.status}`);
        res.status(400).json({
          error: `Failed to get place details: ${data.status}`,
          details: data.error_message || "Unknown error",
        });
        return;
      }
    } catch (error) {
      console.error("Error in getPlaceDetails function:", error);
      res.status(500).json({
        error: "An error occurred while processing your request",
        details: error instanceof Error ? error.message : "Unknown error",
      });
      return;
    }
  }
);

// Send notification when a new vehicle/truck is created or updated to be "live"
export const notifyDealersOnNewVehicle = functions.firestore.onDocumentWritten(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    const vehicleId = event.params.vehicleId;
    const newData = event.data?.after?.data();
    const previousData = event.data?.before?.data();

    // If document was deleted or doesn't have required fields, exit early
    if (!newData) return null;

    // Check if this is a new vehicle (create) or if status changed to "live"
    const isNewVehicle = !previousData;
    const statusChangedToLive =
      previousData &&
      previousData.status !== "live" &&
      newData.status === "live";

    // Only proceed if the vehicle is new or just went live
    if (!isNewVehicle && !statusChangedToLive) return null;

    try {
      // Get vehicle details for the notification
      const brand = newData.brand || "New";
      const model = newData.model || "Vehicle";
      const vehicleType = newData.vehicleType || "truck";
      const year = newData.year || "";

      // Send notification to all dealers subscribed to the topic
      const message = {
        notification: {
          title: "New Truck Available",
          body: `${year} ${brand} ${model} ${vehicleType} is now available`,
        },
        data: {
          vehicleId: vehicleId,
          type: "newVehicle",
        },
        topic: "newVehicles", // Topic for dealers interested in new vehicles
      };

      await admin.messaging().send(message);
      console.log(`Notification sent for vehicle ${vehicleId}`);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  }
);

// Send notification to admins when new dealers or transporters sign up
export const notifyAdminsOnNewUser = functions.firestore.onDocumentCreated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const userData = event.data?.data();
    const userId = event.params.userId;

    // If there's no user data or user role, exit early
    if (!userData || !userData.userRole) return null;

    const userRole = userData.userRole.toLowerCase();

    // Only send notifications for dealer and transporter sign ups
    if (userRole !== "dealer" && userRole !== "transporter") return null;

    try {
      const firstName = userData.firstName || "";
      const lastName = userData.lastName || "";
      const companyName = userData.companyName || "";

      // Choose the appropriate topic based on the user role
      const topic = userRole === "dealer" ? "newDealers" : "newTransporters";

      // Create notification message
      const message = {
        notification: {
          title: `New ${
            userRole.charAt(0).toUpperCase() + userRole.slice(1)
          } Registration`,
          body: `${firstName} ${lastName} from ${companyName} has registered as a ${userRole}.`,
        },
        data: {
          userId: userId,
          userRole: userRole,
          type: "newUser",
        },
        topic: topic,
      };

      // Send the notification
      await admin.messaging().send(message);
      console.log(`Notification sent for new ${userRole} ${userId}`);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  }
);

// Send direct notification to a specific user
export const sendDirectNotification = functions.https.onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // Check if the caller is authenticated
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Function requires authentication"
      );
    }

    const { userId, title, body, dataPayload } = request.data;

    try {
      // Get the user's FCM token
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
      }

      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;

      if (!fcmToken) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "User does not have an FCM token"
        );
      }

      // Create the message
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: dataPayload || {},
        token: fcmToken,
      };

      // Send the notification
      await admin.messaging().send(message);
      return { success: true, message: "Notification sent successfully" };
    } catch (error) {
      console.error("Error sending direct notification:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send notification"
      );
    }
  }
);

// Original function from the codebase - keeping v1 version if it's already being used
export const sendNewVehicleNotification = functionsV1.https.onCall(
  async (request: functionsV1.https.CallableRequest<any>) => {
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
      throw new functionsV1.https.HttpsError(
        "internal",
        "Failed to send notification"
      );
    }
  }
);
