// import lakpahana/firebase_auth;
// import ballerina/http;
// import ballerina/log;
// import ballerina/time;
// import ballerina/uuid;

// // Configuration constants
// const string SERVICE_ACCOUNT_PATH = "path/to/service_account.json";
// const string PRIVATE_KEY_PATH = "path/to/private.key";
// const decimal TOKEN_EXPIRY = 3600.0; // 1 hour in seconds

// // Initialize Firebase Auth client with proper configuration
// final firebase_auth:Client firebaseAuth = check new ({
//     serviceAccountPath: SERVICE_ACCOUNT_PATH,
//     privateKeyPath: PRIVATE_KEY_PATH,
//     jwtConfig: {
//         scope: "https://www.googleapis.com/auth/cloud-platform",
//         expTime: TOKEN_EXPIRY
//     },
//     firebaseConfig: {
//         apiKey: "YOUR_API_KEY",
//         authDomain: "your-project.firebaseapp.com",
//         projectId: "your-project-id",
//         storageBucket: "your-project.appspot.com"
//     }
// });

// public function registerUser(http:Caller caller, http:Request req) returns error? {
//     json|error payload = req.getJsonPayload();
//     if payload is error {
//         log:printError("Invalid payload", payload);
//         return respondError(caller, "Invalid request payload", http:STATUS_BAD_REQUEST);
//     }

//     json requestData = payload;
//     string userId = uuid:createType1AsString();

//     // Create user in Firebase Authentication
//     firebase_auth:Client|error authUser = check firebaseAuth->createUser({
//         uid: userId,
//         email: check extractString(requestData, "email"),
//         displayName: check extractString(requestData, "firstName") + " " + 
//                     (check extractOptionalString(requestData, "lastName") ?: ""),
//         disabled: false
//     });

//     // Generate custom token for client-side auth
//     string|error customToken = check firebaseAuth->createCustomToken(userId);
//     if customToken is error {
//         log:printError("Token generation failed", customToken);
//         // Rollback user creation if token generation fails
//         _ = firebaseAuth->deleteUser(userId);
//         return respondError(caller, "Authentication setup failed", http:STATUS_INTERNAL_SERVER_ERROR);
//     }

//     return respondSuccess(caller, {
//         "userId": userId,
//         "token": customToken,
//         "message": "User registered successfully"
//     });
// }

// public function loginUser(http:Caller caller, http:Request req) returns error? {
//     json|error payload = req.getJsonPayload();
//     if payload is error {
//         return respondError(caller, "Invalid request payload", http:STATUS_BAD_REQUEST);
//     }

//     json requestData = payload;
//     string email = check extractString(requestData, "email");

//     // Get user by email from Firebase
//     firebase_auth:UserRecord|error authUser = check firebaseAuth->getUserByEmail(email);
//     if authUser is error {
//         log:printError("User not found", authUser);
//         return respondError(caller, "Invalid credentials", http:STATUS_UNAUTHORIZED);
//     }

//     // Generate ID token (client should verify password and exchange custom token for ID token)
//     string|error customToken = check firebaseAuth->createCustomToken(authUser.uid);
//     if customToken is error {
//         return respondError(caller, "Authentication failed", http:STATUS_INTERNAL_SERVER_ERROR);
//     }

//     return respondSuccess(caller, {
//         "userId": authUser.uid,
//         "token": customToken,
//         "message": "Login successful"
//     });
// }

// public function verifyToken(http:Caller caller, http:Request req) returns error? {
//     string|error authHeader = req.getHeader("Authorization");
//     if authHeader is error || !authHeader.startsWith("Bearer ") {
//         return respondError(caller, "Missing or invalid authorization header", http:STATUS_UNAUTHORIZED);
//     }

//     string token = authHeader.substring(7);
//     firebase_auth:DecodedToken|error decodedToken = check firebaseAuth->verifyIdToken(token);
//     if decodedToken is error {
//         return respondError(caller, "Invalid token", http:STATUS_UNAUTHORIZED);
//     }

//     return respondSuccess(caller, {
//         "userId": decodedToken.uid,
//         "claims": decodedToken.claims
//     });
// }

// // Helper functions
// function extractString(json data, string field) returns string|error {
//     if !data.hasKey(field) {
//         return error("Missing required field: " + field);
//     }
//     return data[field].toString();
// }

// function extractOptionalString(json data, string field) returns string? {
//     if data.hasKey(field) {
//         return data[field].toString();
//     }
//     return ();
// }

// function respondSuccess(http:Caller caller, json payload) returns error? {
//     return caller->respond({
//         "success": true,
//         "data": payload
//     });
// }

// function respondError(http:Caller caller, string message, int statusCode = http:STATUS_BAD_REQUEST) returns error? {
//     return caller->respond({
//         "success": false,
//         "message": message
//     }, statusCode = statusCode);
// }
