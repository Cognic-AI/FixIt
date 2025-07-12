import backend.firestore.operations as db;

import ballerina/http;
import ballerina/jwt;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

public function registerUser(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();

    if payload is error {
        check caller->respond({
            "success": false,
            "message": "Invalid request payload"
        });
        return;
    }

    json requestData = payload;
    string userId = uuid:createType1AsString();

    json userData = {
        "id": userId,
        "firstName": requestData.firstName,
        "lastName": requestData.lastName,
        "email": requestData.email,
        "userType": requestData.userType,
        "location": requestData?.location ?: "Recife, Brazil",
        "rating": 0.0,
        "reviewCount": 0,
        "verified": false,
        "avatar": requestData?.avatar ?: "",
        "createdAt": time:utcNow()
    };

    var result = db:createDocument("users", userId, userData);

    if result is error {
        log:printError("Error creating user", result);
        check caller->respond({
            "success": false,
            "message": "Failed to create user"
        });
        return;
    }

    // Generate JWT token
    string token = check generateJWTToken(userId, requestData.email.toString());

    check caller->respond({
        "success": true,
        "user": userData,
        "token": token,
        "message": "User created successfully"
    });
}

public function loginUser(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();

    if payload is error {
        check caller->respond({
            "success": false,
            "message": "Invalid request payload"
        });
        return;
    }

    json requestData = payload;
    string email = requestData.email.toString();

    // Query user by email
    var users = db:queryDocuments("users", {"email": email});

    if users is error {
        log:printError("Error fetching user", users);
        check caller->respond({
            "success": false,
            "message": "Login failed"
        });
        return;
    }

    if users.length() == 0 {
        check caller->respond({
            "success": false,
            "message": "User not found"
        });
        return;
    }

    json user = users[0];
    string token = check generateJWTToken(user.id.toString(), email);

    check caller->respond({
        "success": true,
        "user": user,
        "token": token,
        "message": "Login successful"
    });
}

public function logoutUser(http:Caller caller, http:Request req) returns error? {
    // Implement logout logic (token blacklisting, etc.)
    check caller->respond({
        "success": true,
        "message": "Logged out successfully"
    });
}

public function getUserProfile(http:Caller caller, http:Request req, string userId) returns error? {
    var result = db:getDocument("users", userId);

    if result is error {
        check caller->respond({
            "success": false,
            "message": "User not found"
        });
        return;
    }

    check caller->respond({
        "success": true,
        "user": result
    });
}

function generateJWTToken(string userId, string email) returns string|error {
    // Implement JWT token generation
    // This is a simplified version - implement proper JWT generation
    return "jwt-token-" + userId;
}

public function validateToken(string token) returns json|error {
    // Implement token validation
    // Return user data if token is valid
    return {"userId": "demo-user", "email": "demo@example.com"};
}
