// import ballerina/http;
// import ballerina/log;

// configurable string googleMapsApiKey = ?;

// http:Client mapsClient = check new ("https://maps.googleapis.com");

// public function geocodeAddress(http:Caller caller, http:Request req) returns error? {
//     map<string[]> queryParams = req.getQueryParams();
//     string? address = queryParams["address"] is string[] ? queryParams["address"][0] : ();

//     if address is () {
//         check caller->respond({
//             "success": false,
//             "message": "Address parameter is required"
//         });
//         return;
//     }

//     string endpoint = "/maps/api/geocode/json?address=" + address + "&key=" + googleMapsApiKey;

//     var response = mapsClient->get(endpoint);

//     if response is error {
//         log:printError("Error geocoding address", response);
//         check caller->respond({
//             "success": false,
//             "message": "Geocoding service unavailable"
//         });
//         return;
//     }

//     json geocodeResult = check response.getJsonPayload();

//     check caller->respond({
//         "success": true,
//         "result": geocodeResult
//     });
// }

// public function getDirections(http:Caller caller, http:Request req) returns error? {
//     map<string[]> queryParams = req.getQueryParams();
//     string? origin = queryParams["origin"] is string[] ? queryParams["origin"][0] : ();
//     string? destination = queryParams["destination"] is string[] ? queryParams["destination"][0] : ();

//     if origin is () || destination is () {
//         check caller->respond({
//             "success": false,
//             "message": "Origin and destination parameters are required"
//         });
//         return;
//     }

//     string endpoint = "/maps/api/directions/json?origin=" + origin + "&destination=" + destination + "&key=" + googleMapsApiKey;

//     var response = mapsClient->get(endpoint);

//     if response is error {
//         log:printError("Error getting directions", response);
//         check caller->respond({
//             "success": false,
//             "message": "Directions service unavailable"
//         });
//         return;
//     }

//     json directionsResult = check response.getJsonPayload();

//     check caller->respond({
//         "success": true,
//         "result": directionsResult
//     });
// }

// public function getNearbyPlaces(http:Caller caller, http:Request req) returns error? {
//     map<string[]> queryParams = req.getQueryParams();
//     string? location = queryParams["location"] is string[] ? queryParams["location"][0] : ();
//     string? radius = queryParams["radius"] is string[] ? queryParams["radius"][0] : ();
//     string? placeType = queryParams["type"] is string[] ? queryParams["type"][0] : ();

//     if location is () {
//         check caller->respond({
//             "success": false,
//             "message": "Location parameter is required"
//         });
//         return;
//     }

//     string endpoint = "/maps/api/place/nearbysearch/json?location=" + location;

//     if radius is string {
//         endpoint += "&radius=" + radius;
//     }
//     if placeType is string {
//         endpoint += "&type=" + placeType;
//     }

//     endpoint += "&key=" + googleMapsApiKey;

//     var response = mapsClient->get(endpoint);

//     if response is error {
//         log:printError("Error getting nearby places", response);
//         check caller->respond({
//             "success": false,
//             "message": "Places service unavailable"
//         });
//         return;
//     }

//     json placesResult = check response.getJsonPayload();

//     check caller->respond({
//         "success": true,
//         "result": placesResult
//     });
// }
