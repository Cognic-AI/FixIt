import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/uuid;

import lakpahana/firebase_auth;

// Initialize Firebase Auth client
final firebase_auth:Client firebaseAuth = check new ({
    serviceAccountPath: "firebase-service-account.json",
    privateKeyPath: "firebase-private.key",
    jwtConfig: {
        scope: "https://www.googleapis.com/auth/cloud-platform",
        expTime: 3600.0 // 1 hour expiration
    }
});

public isolated function registerUser(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();
    if payload is error {
        log:printError("Invalid payload", payload);
        return respondError(caller, "Invalid request payload", http:STATUS_BAD_REQUEST);
    }

    json requestData = payload;
    string userId = uuid:createType1AsString();
    string email = check extractString(requestData);
    io:println("Email: " + email);
    // Generate custom token for Firebase Auth
    string|error customToken = check firebaseAuth.generateToken();
    if customToken is error {
        log:printError("Token generation failed", customToken);
        return respondError(caller, "Authentication setup failed", http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // In a real implementation, you would:
    // 1. Store user data in your database
    // 2. Use the custom token for client-side Firebase Auth

    return respondSuccess(caller, {
        "userId": userId,
        "token": customToken,
        "message": "Use this token with Firebase client SDK"
    });
}

public isolated function verifyToken(http:Caller caller, http:Request req) returns error? {
    string|error authHeader = req.getHeader("Authorization");
    if authHeader is error || !authHeader.startsWith("Bearer ") {
        return respondError(caller, "Missing or invalid authorization header", http:STATUS_UNAUTHORIZED);
    }

    string token = authHeader.substring(7);

    // In this version of the module, you would need to verify the token
    // using Firebase Admin SDK on your backend or through another service

    return respondSuccess(caller, {
        "message": "Token verification would be implemented here",
        "token": token
    });
}

public isolated function login(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();
    if payload is error {
        log:printError("Invalid payload", payload);
        return respondError(caller, "Invalid request payload", http:STATUS_BAD_REQUEST);
    }

    json requestData = payload;
    string email = check extractString(requestData);
    io:println("Email: " + email);
    // Authenticate user with Firebase Auth
    string|error idToken = check verifyIdToken(email);
    if idToken is error {
        log:printError("Token verification failed", idToken);
        return respondError(caller, "Authentication failed", http:STATUS_UNAUTHORIZED);
    }

    return respondSuccess(caller, {
        "message": "Login successful",
        "token": idToken
    });
}

isolated function verifyIdToken(string email) returns string|error {
    // Simulate token verification logic
    if email == "sahan@fixit.lk" {
        return "valid-id-token";
    }
    return error("Invalid email");
}

isolated function extractString(json data) returns string|error {
    if !(data is map<json>) || !data.hasKey("email") {
        return error("Missing required field: " + "email");
    }
    json value = data["email"];
    if value is string {
        return value;
    }
    return value.toString();
}

isolated function respondSuccess(http:Caller caller, json payload) returns error? {
    return caller->respond({
        "success": true,
        "data": payload
    });
}

isolated function respondError(http:Caller caller, string message, int statusCode = http:STATUS_BAD_REQUEST) returns error? {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload({
        "success": false,
        "message": message
    });
    return caller->respond(response);
}
