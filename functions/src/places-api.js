const functions = require("firebase-functions");
const { onRequest } = require("firebase-functions/v2/https");

// Remember to set PLACES_API_KEY via environment variables for Firebase Functions v2

// Places Autocomplete API to search for locations
exports.placesAutocomplete = onRequest(async (req, res) => {
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

    // Get the input query parameter from the request and trim whitespace
    const input = (req.query.input || "").toString().trim();

    if (!input) {
      return res.status(400).json({
        error: "Missing required parameter: input",
      });
    }

    // Get Google Places API key from environment variables
    const apiKey = process.env.PLACES_API_KEY;

    if (!apiKey) {
      console.error("Google Places API key is not configured");
      return res.status(500).json({
        error: "Server configuration error: Missing API key",
      });
    }

    console.log(`Fetching places suggestions for query: "${input}"`);

    // Construct the Google Places API URL with country restriction (no strict address type)
    const url =
      `https://maps.googleapis.com/maps/api/place/autocomplete/json` +
      `?input=${encodeURIComponent(input)}` +
      `&components=country:za` +
      `&key=${apiKey}`;
    console.log("Autocomplete URL:", url);

    // Make the request to Google Places API
    const response = await fetch(url);
    const data = await response.json();
    console.log("Autocomplete response data:", JSON.stringify(data, null, 2));

    console.log(
      `Received ${data.predictions?.length || 0} predictions from Places API`
    );

    // Fallback to Text Search API if no autocomplete predictions
    let predictions = data.predictions || [];

    // If no autocomplete predictions, fallback to text search
    if (!predictions.length) {
      console.log("No autocomplete results, falling back to textsearch");
      const searchUrl =
        `https://maps.googleapis.com/maps/api/place/textsearch/json` +
        `?query=${encodeURIComponent(input)}` +
        `&region=za` +
        `&key=${apiKey}`;
      console.log("TextSearch URL:", searchUrl);
      const searchResp = await fetch(searchUrl);
      const searchRaw = await searchResp.text();
      console.log("TextSearch raw response:", searchRaw);
      const searchData = JSON.parse(searchRaw);
      predictions = (searchData.results || []).map((r) => ({
        description: r.formatted_address,
        place_id: r.place_id,
      }));
    }

    // Return only the predictions array
    return res.status(200).json({ predictions });
  } catch (error) {
    console.error("Error in placesAutocomplete function:", error);
    return res.status(500).json({
      error: "An error occurred while processing your request",
      details: error.message,
    });
  }
});

// Get place details including lat/lng coordinates for a place ID
exports.getPlaceDetails = onRequest(async (req, res) => {
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

    if (!placeId) {
      return res.status(400).json({
        error: "Missing required parameter: placeId",
      });
    }

    // Get the API key from environment variables
    const apiKey = process.env.PLACES_API_KEY;

    if (!apiKey) {
      console.error("Google Places API key is not configured");
      return res.status(500).json({
        error: "Server configuration error: Missing API key",
      });
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
          } else if (component.types.includes("administrative_area_level_1")) {
            result.state = component.long_name;
          } else if (component.types.includes("postal_code")) {
            result.postalCode = component.long_name;
          }
        }
      }

      console.log(`Successfully retrieved details for place ID: "${placeId}"`);
      return res.status(200).json(result);
    } else {
      console.error(`Failed to get place details: ${data.status}`);
      return res.status(400).json({
        error: `Failed to get place details: ${data.status}`,
        details: data.error_message || "Unknown error",
      });
    }
  } catch (error) {
    console.error("Error in getPlaceDetails function:", error);
    return res.status(500).json({
      error: "An error occurred while processing your request",
      details: error.message,
    });
  }
});
