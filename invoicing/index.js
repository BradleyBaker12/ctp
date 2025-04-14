/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const fetch = require("node-fetch"); // For Node versions before 18

// Constants for the Sage API
const SAGE_API_BASE = "https://resellers.accounting.sageone.co.za/api/2.0.0";
const USERNAME = "cajunbeeby@gmail.com";
const PASSWORD = "SageAccounting@1";
const API_KEY = "D95FB388-B362-4348-B582-F12159170FCD";
const basicAuth =
  "Basic " + Buffer.from(`${USERNAME}:${PASSWORD}`).toString("base64");

/**
 * A proxy function for Sage API calls.
 *
 * Query parameters:
 *   target: Specifies which Sage API endpoint to call. Acceptable values:
 *     - customerGet
 *     - customerSave
 *     - taxInvoiceSave
 *     - taxInvoiceExport
 *
 *   Optional parameters:
 *     For customerGet: filterName (the customer's name)
 *     For taxInvoiceExport: invoiceId (the invoice ID)
 *
 * For POST requests (customerSave, taxInvoiceSave), the request body is forwarded to Sage.
 */
exports.proxySageAPI = functions.https.onRequest(async (req, res) => {
  // Set CORS headers
  res.set("Access-Control-Allow-Origin", "*"); // Change '*' to your domain for production
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set(
    "Access-Control-Allow-Headers",
    "Content-Type, Authorization, X-API-KEY"
  );

  // Handle preflight requests
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Determine the target endpoint based on a query parameter
  const target = req.query.target;
  let endpoint = "";
  let method = req.method; // Use the incoming request's method
  let body = req.body;

  if (target === "customerGet") {
    const filterName = req.query.filterName;
    if (!filterName) {
      res.status(400).send("Missing parameter: filterName");
      return;
    }
    endpoint = `${SAGE_API_BASE}/Customer/Get?filter.Name=${encodeURIComponent(
      filterName
    )}`;
  } else if (target === "customerSave") {
    endpoint = `${SAGE_API_BASE}/Customer/Save`;
  } else if (target === "taxInvoiceSave") {
    endpoint = `${SAGE_API_BASE}/TaxInvoice/Save`;
  } else if (target === "taxInvoiceExport") {
    const invoiceId = req.query.invoiceId;
    if (!invoiceId) {
      res.status(400).send("Missing parameter: invoiceId");
      return;
    }
    endpoint = `${SAGE_API_BASE}/TaxInvoice/Export/${encodeURIComponent(
      invoiceId
    )}`;
  } else {
    res.status(400).send("Invalid target");
    return;
  }

  try {
    // Build the options for the fetch call
    const options = {
      method: target === "customerGet" ? "GET" : method,
      headers: {
        "Content-Type": "application/json",
        Authorization: basicAuth,
        "X-API-KEY": API_KEY,
      },
      // Only include body for non-GET requests
      body:
        target === "customerGet" || method === "GET"
          ? undefined
          : JSON.stringify(body),
    };

    // Send request to the Sage API endpoint
    const sageResponse = await fetch(endpoint, options);
    const responseText = await sageResponse.text();

    // Attempt to parse JSON response if possible
    try {
      const jsonResponse = JSON.parse(responseText);
      res.status(sageResponse.status).json(jsonResponse);
    } catch (err) {
      // If not JSON, simply return the text
      res.status(sageResponse.status).send(responseText);
    }
  } catch (error) {
    console.error("Error in proxySageAPI:", error);
    res.status(500).json({ error: error.toString() });
  }
});
