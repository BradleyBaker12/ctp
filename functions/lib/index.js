"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNewVehicleNotification = exports.sendDirectNotification = exports.notifyAdminsOnNewUser = exports.notifyDealersOnNewVehicle = exports.getPlaceDetails = exports.placesAutocomplete = void 0;
const functions = __importStar(require("firebase-functions/v2"));
const functionsV1 = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const node_fetch_1 = __importDefault(require("node-fetch"));
admin.initializeApp();
// Places Autocomplete API for location search
exports.placesAutocomplete = functions.https.onRequest({
    region: "europe-west3",
    cors: true,
    maxInstances: 10,
}, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
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
        console.log("placesAutocomplete function called with input:", req.query.input);
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
        const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${apiKey}`;
        // Make the request to Google Places API
        const response = yield (0, node_fetch_1.default)(url);
        const data = yield response.json();
        console.log(`Received ${((_a = data.predictions) === null || _a === void 0 ? void 0 : _a.length) || 0} predictions from Places API`);
        // Return the response
        res.status(200).json(data);
        return;
    }
    catch (error) {
        console.error("Error in placesAutocomplete function:", error);
        res.status(500).json({
            error: "An error occurred while processing your request",
            details: error instanceof Error ? error.message : "Unknown error",
        });
        return;
    }
}));
// Get place details including lat/lng coordinates for a place ID
exports.getPlaceDetails = functions.https.onRequest({
    region: "europe-west3",
    cors: true,
    maxInstances: 10,
}, (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b, _c, _d;
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
        const response = yield (0, node_fetch_1.default)(url);
        const data = yield response.json();
        // If the request was successful and we have results
        if (data.status === "OK" && data.result) {
            // Extract the important details we need
            const result = {
                lat: (_b = (_a = data.result.geometry) === null || _a === void 0 ? void 0 : _a.location) === null || _b === void 0 ? void 0 : _b.lat,
                lng: (_d = (_c = data.result.geometry) === null || _c === void 0 ? void 0 : _c.location) === null || _d === void 0 ? void 0 : _d.lng,
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
                    }
                    else if (component.types.includes("administrative_area_level_1")) {
                        result.state = component.long_name;
                    }
                    else if (component.types.includes("postal_code")) {
                        result.postalCode = component.long_name;
                    }
                }
            }
            console.log(`Successfully retrieved details for place ID: "${placeId}"`);
            res.status(200).json(result);
            return;
        }
        else {
            console.error(`Failed to get place details: ${data.status}`);
            res.status(400).json({
                error: `Failed to get place details: ${data.status}`,
                details: data.error_message || "Unknown error",
            });
            return;
        }
    }
    catch (error) {
        console.error("Error in getPlaceDetails function:", error);
        res.status(500).json({
            error: "An error occurred while processing your request",
            details: error instanceof Error ? error.message : "Unknown error",
        });
        return;
    }
}));
// Send notification when a new vehicle/truck is created or updated to be "live"
exports.notifyDealersOnNewVehicle = functions.firestore.onDocumentWritten({
    document: "vehicles/{vehicleId}",
    region: "us-central1",
}, (event) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b, _c, _d;
    const vehicleId = event.params.vehicleId;
    const newData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.after) === null || _b === void 0 ? void 0 : _b.data();
    const previousData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.before) === null || _d === void 0 ? void 0 : _d.data();
    // If document was deleted or doesn't have required fields, exit early
    if (!newData)
        return null;
    // Check if this is a new vehicle (create) or if status changed to "live"
    const isNewVehicle = !previousData;
    const statusChangedToLive = previousData &&
        previousData.status !== "live" &&
        newData.status === "live";
    // Only proceed if the vehicle is new or just went live
    if (!isNewVehicle && !statusChangedToLive)
        return null;
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
        yield admin.messaging().send(message);
        console.log(`Notification sent for vehicle ${vehicleId}`);
    }
    catch (error) {
        console.error("Error sending notification:", error);
    }
}));
// Send notification to admins when new dealers or transporters sign up
exports.notifyAdminsOnNewUser = functions.firestore.onDocumentCreated({
    document: "users/{userId}",
    region: "us-central1",
}, (event) => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const userData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    const userId = event.params.userId;
    // If there's no user data or user role, exit early
    if (!userData || !userData.userRole)
        return null;
    const userRole = userData.userRole.toLowerCase();
    // Only send notifications for dealer and transporter sign ups
    if (userRole !== "dealer" && userRole !== "transporter")
        return null;
    try {
        const firstName = userData.firstName || "";
        const lastName = userData.lastName || "";
        const companyName = userData.companyName || "";
        // Choose the appropriate topic based on the user role
        const topic = userRole === "dealer" ? "newDealers" : "newTransporters";
        // Create notification message
        const message = {
            notification: {
                title: `New ${userRole.charAt(0).toUpperCase() + userRole.slice(1)} Registration`,
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
        yield admin.messaging().send(message);
        console.log(`Notification sent for new ${userRole} ${userId}`);
    }
    catch (error) {
        console.error("Error sending notification:", error);
    }
}));
// Send direct notification to a specific user
exports.sendDirectNotification = functions.https.onCall({
    region: "us-central1",
}, (request) => __awaiter(void 0, void 0, void 0, function* () {
    // Check if the caller is authenticated
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Function requires authentication");
    }
    const { userId, title, body, dataPayload } = request.data;
    try {
        // Get the user's FCM token
        const userDoc = yield admin
            .firestore()
            .collection("users")
            .doc(userId)
            .get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User not found");
        }
        const userData = userDoc.data();
        const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
        if (!fcmToken) {
            throw new functions.https.HttpsError("failed-precondition", "User does not have an FCM token");
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
        yield admin.messaging().send(message);
        return { success: true, message: "Notification sent successfully" };
    }
    catch (error) {
        console.error("Error sending direct notification:", error);
        throw new functions.https.HttpsError("internal", "Failed to send notification");
    }
}));
// Original function from the codebase - keeping v1 version if it's already being used
exports.sendNewVehicleNotification = functionsV1.https.onCall((request) => __awaiter(void 0, void 0, void 0, function* () {
    const { vehicleId } = request.data;
    try {
        const vehicleSnap = yield admin
            .firestore()
            .collection("vehicles")
            .doc(vehicleId)
            .get();
        const vehicleData = vehicleSnap.data();
        if (!vehicleData)
            return;
        const message = {
            notification: {
                title: "New Vehicle Available",
                body: `A new ${vehicleData.brand} ${vehicleData.model} is now available`,
            },
            topic: "newVehicles",
        };
        yield admin.messaging().send(message);
    }
    catch (error) {
        console.error("Error sending notification:", error);
        throw new functionsV1.https.HttpsError("internal", "Failed to send notification");
    }
}));
