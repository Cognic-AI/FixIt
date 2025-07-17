// import backend.mongodb;

// import ballerina/http;
// import ballerina/io;
// import ballerina/regex;
// import ballerina/time;

// // Google Maps API configuration
// configurable string googleMapsApiKey = ?;

// // Location record types
// public type Location record {
//     float latitude;
//     float longitude;
// };

// public type LocationString record {
//     string locationStr;
// };

// public type NearbyVendor record {
//     string id;
//     string email;
//     string firstName;
//     string lastName;
//     string? phoneNumber;
//     string role;
//     string category;
//     float? latitude;
//     float? longitude;
//     float distance; // in kilometers
// };

// public type DirectionsResponse record {
//     string status;
//     Route[] routes;
// };

// public type Route record {
//     Leg[] legs;
//     string summary;
//     string? copyrights;
// };

// public type Leg record {
//     Distance distance;
//     Duration duration;
//     string end_address;
//     string start_address;
//     float end_latitude;
//     float end_longitude;
//     float start_latitude;
//     float start_longitude;
//     Step[] steps;
// };

// public type Distance record {
//     string text;
//     int value; // in meters
// };

// public type Duration record {
//     string text;
//     int value; // in seconds
// };

// public type Step record {
//     Distance distance;
//     Duration duration;
//     float end_latitude;
//     float end_longitude;
//     float start_latitude;
//     float start_longitude;
//     string html_instructions;
//     string travel_mode;
// };

// // HTTP client for Google Maps API
// final http:Client googleMapsClient = check new ("https://maps.googleapis.com");

// // Utility function to format location as string
// public function formatLocationString(Location location) returns string {
//     return string `(${location.latitude},${location.longitude})`;
// }

// // Calculate distance between two locations using Haversine formula
// // Calculate distance between two locations using Haversine formula
// public function calculateDistance(float[] loc1, float[] loc2) returns float {
//     float earthRadius = 6371.0; // Earth's radius in kilometers
//     float pi = 3.14159265359;

//     float lat1 = loc1[0];
//     float lon1 = loc1[1];
//     float lat2 = loc2[0];
//     float lon2 = loc2[1];

//     // Convert degrees to radians
//     float lat1Rad = lat1 * pi / 180.0;
//     float lng1Rad = lon1 * pi / 180.0;
//     float lat2Rad = lat2 * pi / 180.0;
//     float lng2Rad = lon2 * pi / 180.0;

//     // Haversine formula
//     float deltaLat = lat2Rad - lat1Rad;
//     float deltaLng = lng2Rad - lng1Rad;

//     float sinDeltaLat = deltaSin(deltaLat / 2);
//     float sinDeltaLng = deltaSin(deltaLng / 2);
//     float cosLat1 = deltaCos(lat1Rad);
//     float cosLat2 = deltaCos(lat2Rad);

//     float a = sinDeltaLat * sinDeltaLat +
//             cosLat1 * cosLat2 * sinDeltaLng * sinDeltaLng;

//     float c = 2 * deltaAtan2(deltaSqrt(a), deltaSqrt(1 - a));

//     return earthRadius * c;
// }

// // Helper functions for basic trigonometric calculations
// function deltaSin(float x) returns float {
//     // Taylor series approximation for sin(x)
//     float result = x;
//     float term = x;
//     int i = 1;
//     while i < 10 {
//         term = term * (-1) * x * x / ((2 * i) * (2 * i + 1));
//         result = result + term;
//         i = i + 1;
//     }
//     return result;
// }

// function deltaCos(float x) returns float {
//     // Taylor series approximation for cos(x)
//     float result = 1.0;
//     float term = 1.0;
//     int i = 1;
//     while i < 10 {
//         term = term * (-1) * x * x / ((2 * i - 1) * (2 * i));
//         result = result + term;
//         i = i + 1;
//     }
//     return result;
// }

// function deltaSqrt(float x) returns float {
//     if x <= 0.0 {
//         return 0.0;
//     }
//     // Newton's method for square root
//     float guess = x / 2;
//     int iterations = 10;
//     int i = 0;
//     while i < iterations {
//         guess = (guess + x / guess) / 2;
//         i = i + 1;
//     }
//     return guess;
// }

// function deltaAtan2(float y, float x) returns float {
//     if x > 0.0 {
//         return deltaAtan(y / x);
//     } else if x < 0.0 && y >= 0.0 {
//         return deltaAtan(y / x) + 3.14159265359;
//     } else if x < 0.0 && y < 0.0 {
//         return deltaAtan(y / x) - 3.14159265359;
//     } else if x == 0.0 && y > 0.0 {
//         return 3.14159265359 / 2.0;
//     } else if x == 0.0 && y < 0.0 {
//         return -3.14159265359 / 2.0;
//     }
//     return 0.0; // x == 0 && y == 0
// }

// function deltaAtan(float x) returns float {
//     // Series approximation for atan(x)
//     if x > 1.0 {
//         return 3.14159265359 / 2 - deltaAtan(1.0 / x);
//     } else if x < -1.0 {
//         return -3.14159265359 / 2 - deltaAtan(1.0 / x);
//     }

//     float result = x;
//     float term = x;
//     int i = 1;
//     while i < 10 {
//         term = term * (-1) * x * x;
//         result = result + term / (2 * i + 1);
//         i = i + 1;
//     }
//     return result;
// }

// // Get current location from request (if sent from frontend)
// public function getCurrentLocationFromRequest(http:Request req) returns float[]|error {
//     json payload = check req.getJsonPayload();

//     if payload.latitude is () || payload.longitude is () {
//         return error("Location coordinates not provided in request");
//     }

//     float lat = check payload.latitude;
//     float lng = check payload.longitude;

//     if lat is error || lng is error {
//         return error("Invalid location coordinates");
//     }

//     return [lat, lng];
// }

// // Get user/vendor location from database
// public function getUserLocation(string email) returns float[]|error {
//     map<json> filter = {"email": email};
//     map<json>|error userDoc = mongodb:getDocumentWithFilters("users", filter);

//     if userDoc is error {
//         return error("User not found: " + userDoc.message());
//     }

//     json latitudeJson = userDoc["latitude"];
//     json longitudeJson = userDoc["longitude"];

//     if latitudeJson is () || longitudeJson is () {
//         return error("Location not set for user");
//     }

//     float|error latitude = float:fromString(latitudeJson.toString());
//     float|error longitude = float:fromString(longitudeJson.toString());

//     if latitude is error || longitude is error {
//         return error("Invalid location coordinates in database");
//     }

//     float[] location = [latitude, longitude];
//     return location;
// }

// // Update user location in database
// public function updateUserLocation(string email, Location location) returns error? {
//     string locationStr = formatLocationString(location);

//     map<json> filter = {"email": email};
//     map<json>|error userDoc = mongodb:getDocumentWithFilters("users", filter);

//     if userDoc is error {
//         return error("User not found: " + userDoc.message());
//     }

//     json userIdField = userDoc["id"];
//     if userIdField is () {
//         return error("User ID not found");
//     }

//     string userId = userIdField.toString();
//     map<json> updateData = {
//         "location": locationStr,
//         "updatedAt": time:utcNow().toString()
//     };

//     return mongodb:updateDocument("users", userId, updateData);
// }

// // Find nearby vendors of a specific category
// public function findNearbyVendors(float[] userLocation, string category, float maxDistance = 50.0) returns NearbyVendor[]|error {
//     io:println("🔍 Finding nearby vendors for category: ", category);

//     // Get all vendors of the specified category
//     map<json> filter = {"role": "vendor", "category": category};
//     mongodb:User[]|error users = mongodb:queryUsers("users", filter);
//     if users is error {
//         return error("Error querying vendors: " + users.message());
//     }

//     NearbyVendor[] nearbyVendors = [];

//     foreach mongodb:User user in users {
//         float distance = calculateDistance(userLocation, vendorLocation);

//         if distance <= maxDistance {
//             NearbyVendor nearbyVendor = {
//                 id: user.id,
//                 email: user.email,
//                 firstName: user.firstName,
//                 lastName: user.lastName,
//                 phoneNumber: user.phoneNumber,
//                 role: user.role,
//                 category: user.category ?: "",
//                 latitude: vendorLocation[0],
//                 longitude: vendorLocation[1],
//                 distance: distance
//             };
//             nearbyVendors.push(nearbyVendor);
//         }
//     }

//     // Sort by distance (closest first)
//     nearbyVendors.sort

//     (function(NearbyVendor a, NearbyVendor b) returns int {
//         if a.distance < b.distance {
//             return -1;
//         } else if a.distance > b.distance {
//             return 1;
//         } else {
//             return 0;
//         }
//     });
// }

// io:println ("Found ", nearbyVendors .length(), " nearby vendors within ", maxDistance, " km" );
// return nearbyVendors ;

// }

// io:println ("Found ", nearbyVendors .length(), " nearby vendors within ", maxDistance, " km" );
// return nearbyVendors ;

// }

// // Get directions between two locations using Google Maps Directions API
// public function getDirections(float[] origin, float[] destination, string mode = "driving") returns DirectionsResponse|error {
//     io:println("Getting directions from Google Maps API");

//     string originStr = string `${origin[0]},${origin[1]}`;
//     string destinationStr = string `${destination[0]},${destination[1]}`;

//     string endpoint = string `/maps/api/directions/json?origin=${originStr}&destination=${destinationStr}&mode=${mode}&key=${googleMapsApiKey}`;

//     http:Response|error response = googleMapsClient->get(endpoint);

//     if response is error {
//         return error("Error calling Google Maps API: " + response.message());
//     }

//     json|error jsonResponse = response.getJsonPayload();
//     if jsonResponse is error {
//         return error("Error parsing Google Maps response: " + jsonResponse.message());
//     }

//     // Parse the response
//     DirectionsResponse|error directionsResponse = jsonResponse.cloneWithType(DirectionsResponse);
//     if directionsResponse is error {
//         return error("Error parsing directions response: " + directionsResponse.message());
//     }

//     io:println("Directions retrieved successfully");
//     return directionsResponse;
// }

// // Get distance matrix between multiple origins and destinations
// public function getDistanceMatrix(float[][] origins, float[][] destinations, string mode = "driving") returns json|error {
//     io:println("Getting distance matrix from Google Maps API");

//     string originsStr = "";
//     foreach int i in 0 ..< origins.length() {
//         if i > 0 {
//             originsStr += "|";
//         }
//         originsStr += string `${origins[i][0]},${origins[i][1]}`;
//     }

//     string destinationsStr = "";
//     foreach int i in 0 ..< destinations.length() {
//         if i > 0 {
//             destinationsStr += "|";
//         }
//         destinationsStr += string `${destinations[i][0]},${destinations[i][1]}`;
//     }

//     string endpoint = string `/maps/api/distancematrix/json?origins=${originsStr}&destinations=${destinationsStr}&mode=${mode}&key=${googleMapsApiKey}`;

//     http:Response|error response = googleMapsClient->get(endpoint);

//     if response is error {
//         return error("Error calling Google Maps API: " + response.message());
//     }

//     json|error jsonResponse = response.getJsonPayload();
//     if jsonResponse is error {
//         return error("Error parsing Google Maps response: " + jsonResponse.message());
//     }

//     io:println("Distance matrix retrieved successfully");
//     return jsonResponse;
// }

// // Geocode an address to get coordinates
// public function geocodeAddress(string address) returns Location|error {
//     io:println("Geocoding address: ", address);

//     string endpoint = string `/maps/api/geocode/json?address=${address}&key=${googleMapsApiKey}`;

//     http:Response|error response = googleMapsClient->get(endpoint);

//     if response is error {
//         return error("Error calling Google Maps API: " + response.message());
//     }

//     json|error jsonResponse = response.getJsonPayload();
//     if jsonResponse is error {
//         return error("Error parsing Google Maps response: " + jsonResponse.message());
//     }

//     json status = check jsonResponse.status;
//     if status.toString() != "OK" {
//         return error("Geocoding failed: " + status.toString());
//     }

//     json results = check jsonResponse.results;
//     if results is json[] && results.length() > 0 {
//         json firstResult = results[0];
//         json geometry = check firstResult.geometry;
//         json location = check geometry.location;

//         float|error lat = float:fromString(location.lat.toString());
//         float|error lng = float:fromString(location.lng.toString());

//         if lat is error || lng is error {
//             return error("Invalid coordinates in geocoding response");
//         }

//         Location result = {
//             latitude: lat,
//             longitude: lng
//         };

//         io:println("✅ Address geocoded successfully");
//         return result;
//     }

//     return error("No results found for address");
// }

// // Reverse geocode coordinates to get address
// public function reverseGeocode(Location location) returns string|error {
//     io:println("🔄 Reverse geocoding location");

//     string latlng = string `${location.latitude},${location.longitude}`;
//     string endpoint = string `/maps/api/geocode/json?latlng=${latlng}&key=${googleMapsApiKey}`;

//     http:Response|error response = googleMapsClient->get(endpoint);

//     if response is error {
//         return error("Error calling Google Maps API: " + response.message());
//     }

//     json|error jsonResponse = response.getJsonPayload();
//     if jsonResponse is error {
//         return error("Error parsing Google Maps response: " + jsonResponse.message());
//     }

//     json status = check jsonResponse.status;
//     if status.toString() != "OK" {
//         return error("Reverse geocoding failed: " + status.toString());
//     }

//     json results = check jsonResponse.results;
//     if results is json[] && results.length() > 0 {
//         json firstResult = results[0];
//         json formattedAddress = check firstResult.formatted_address;

//         io:println("Location reverse geocoded successfully");
//         return formattedAddress.toString();
//     }

//     return error("No address found for location");
// }

// // Service endpoint functions for REST API integration

// // Get nearby vendors endpoint
// public function getNearbyVendorsEndpoint(http:Caller caller, http:Request req, string category) returns error? {
//     io:println("🌐 Processing nearby vendors request for category: ", category);

//     Location|error userLocation = getCurrentLocationFromRequest(req);
//     if userLocation is error {
//         json errorResponse = {
//             "message": "Invalid location data: " + userLocation.message(),
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get maxDistance from query params (optional)
//     float maxDistance = 50.0; // default
//     string? maxDistanceParam = req.getQueryParamValue("maxDistance");
//     if maxDistanceParam is string {
//         float|error parsedDistance = float:fromString(maxDistanceParam);
//         if parsedDistance is float {
//             maxDistance = parsedDistance;
//         }
//     }

//     NearbyVendor[]|error vendors = findNearbyVendors(userLocation, category, maxDistance);

//     if vendors is error {
//         json errorResponse = {
//             "message": "Error finding nearby vendors: " + vendors.message(),
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Nearby vendors retrieved successfully",
//         "statusCode": 200,
//         "data": vendors,
//         "count": vendors.length()
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
// }

// // Get directions endpoint
// public function getDirectionsEndpoint(http:Caller caller, http:Request req) returns error? {
//     io:println("🌐 Processing directions request");

//     json|error payload = req.getJsonPayload();
//     if payload is error {
//         json errorResponse = {
//             "message": "Invalid request payload: " + payload.message(),
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Parse origin and destination
//     json originJson = check payload.origin;
//     json destinationJson = check payload.destination;

//     float|error originLat = float:fromString(originJson.latitude.toString());
//     float|error originLng = float:fromString(originJson.longitude.toString());
//     float|error destLat = float:fromString(destinationJson.latitude.toString());
//     float|error destLng = float:fromString(destinationJson.longitude.toString());

//     if originLat is error || originLng is error || destLat is error || destLng is error {
//         json errorResponse = {
//             "message": "Invalid coordinates in request",
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     Location origin = {latitude: originLat, longitude: originLng};
//     Location destination = {latitude: destLat, longitude: destLng};

//     string mode = payload.mode is json ? payload.mode.toString() : "driving";

//     DirectionsResponse|error directions = getDirections(origin, destination, mode);

//     if directions is error {
//         json errorResponse = {
//             "message": "Error getting directions: " + directions.message(),
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Directions retrieved successfully",
//         "statusCode": 200,
//         "data": directions
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
// }

// // Update user location endpoint
// public function updateLocationEndpoint(http:Caller caller, http:Request req) returns error? {
//     io:println("🌐 Processing location update request");

//     // Get user from authentication
//     // auth:User|error user = auth:authenticateRequest(req);
//     // if user is error {
//     //     json errorResponse = {
//     //         "message": "Unauthorized: " + user.message(),
//     //         "statusCode": 401
//     //     };
//     //     http:Response response = new;
//     //     response.statusCode = 401;
//     //     response.setJsonPayload(errorResponse);
//     //     check caller->respond(response);
//     //     return;
//     // }

//     Location|error location = getCurrentLocationFromRequest(req);
//     if location is error {
//         json errorResponse = {
//             "message": "Invalid location data: " + location.message(),
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // For now, get email from request payload (in production, use authenticated user)
//     json|error payload = req.getJsonPayload();
//     if payload is error {
//         json errorResponse = {
//             "message": "Invalid request payload",
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     string email = check payload.email.toString();

//     error? updateResult = updateUserLocation(email, location);

//     if updateResult is error {
//         json errorResponse = {
//             "message": "Error updating location: " + updateResult.message(),
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Location updated successfully",
//         "statusCode": 200,
//         "location": location
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
// }
