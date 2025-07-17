import backend.utils as utils;
import ballerina/crypto;
import ballerina/http;
import ballerina/io;
import ballerina/lang.array;
import ballerina/log;
import ballerina/regex;
import ballerina/time;
import ballerina/uuid;
import backend.models;

// JWT Configuration
configurable string jwtSecretKey = ?;
configurable decimal jwtExpirationTime = 86400; // 24 hours in seconds

// User model types

public type UserRegistration record {
    string email;
    string password;
    string firstName;
    string lastName;
    string? phoneNumber;
    string role; // "customer" or "provider"
};

public type UserLogin record {
    string email;
    string password;
};

public type AuthResponse record {
    string token;
    models:User user;
    string message;
};

public type ErrorResponse record {
    string message;
    int statusCode;
};

// Hash password using SHA-256
function hashPassword(string password) returns string|error {
    byte[] hashedBytes = crypto:hashSha256(password.toBytes());
    return hashedBytes.toBase16();
}

// Verify password
function verifyPassword(string password, string hashedPassword) returns boolean|error {
    string hashedInput = check hashPassword(password);
    return hashedInput == hashedPassword;
}

// Generate simple JWT token (for development - in production use proper signing)
function generateJWTToken(models:User user) returns string|error {
    // Create a simple token with base64 encoding for development
    string payload = string `{"userId":"${user.id}","email":"${user.email}","role":"${user.role}","firstName":"${user.firstName}","lastName":"${user.lastName}","exp":${<decimal>time:utcNow()[0] + jwtExpirationTime}}`;
    byte[] payloadBytes = payload.toBytes();
    string encodedPayload = payloadBytes.toBase64();

    // Simple token format: fixit.{base64payload}.signature
    string signature = crypto:hashSha256((jwtSecretKey + encodedPayload).toBytes()).toBase16();
    return string `fixit.${encodedPayload}.${signature}`;
}

// Verify JWT token
public function verifyJWTToken(string token) returns map<json>|error {
    string[] parts = regex:split(token, "\\.");
    if parts.length() != 3 || parts[0] != "fixit" {
        return error("Invalid token format");
    }

    string encodedPayload = parts[1];
    string providedSignature = parts[2];

    // Verify signature
    string expectedSignature = crypto:hashSha256((jwtSecretKey + encodedPayload).toBytes()).toBase16();
    if providedSignature != expectedSignature {
        return error("Invalid token signature");
    }
    // Decode payload
    byte[]|error decodedBytes = array:fromBase64(encodedPayload);
    if decodedBytes is error {
        return error("Failed to decode token payload");
    }

    string payloadStr = check string:fromBytes(decodedBytes);
    json|error payload = payloadStr.fromJsonString();
    if payload is error {
        return error("Invalid token payload format");
    }

    map<json> payloadMap = <map<json>>payload;

    // Check expiration
    json expJson = payloadMap["exp"] ?: 0;
    decimal exp = <decimal>expJson;
    if exp < <decimal>time:utcNow()[0] {
        return error("Token has expired");
    }

    return payloadMap;
}

// User registration
public function _registerUser(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();
    if payload is error {
        json errorResponse = {
            "message": "Invalid request payload",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    UserRegistration|error userReg = payload.cloneWithType(UserRegistration);
    if userReg is error {
        json errorResponse = {
            "message": "Invalid request payload format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Validate required fields
    if userReg.email.length() == 0 || userReg.password.length() == 0 ||
        userReg.firstName.length() == 0 || userReg.lastName.length() == 0 {
        json errorResponse = {
            "message": "Email, password, firstName, and lastName are required",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Check if user already exists
    json|error existingUser = models:getDocument("users", <string>userReg.email);
    if existingUser is json {
        json errorResponse = {
            "message": "User with this email already exists",
            "statusCode": 409
        };
        http:Response response = new;
        response.statusCode = 409;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    else {
        io:println("No existing user found with email: " + userReg.email);
    }

    // Hash password
    string hashedPassword = check hashPassword(userReg.password);

    // Create user object
    string userId = uuid:createType1AsString();
    string currentTime = time:utcToString(time:utcNow());

    models:User newUser = {
        id: userId,
        email: userReg.email,
        firstName: userReg.firstName,
        lastName: userReg.lastName,
        phoneNumber: userReg.phoneNumber,
        role: userReg.role == "vendor" ? "vendor" : "client",
        password: hashedPassword,
        emailVerified: false,
        profileImageUrl: (),
        createdAt: currentTime,
        updatedAt: currentTime,
        lastLoginAt: ()
    };

    // Save user to Firestore using email as document ID for consistent lookup
    string|error documentId = utils:generateAlphanumericId();
    if documentId is error {
        log:printError("Failed to generate document ID", documentId);
        json errorResponse = {
            "message": "Internal server error",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    string|error createResult = models:createDocument("users", <map<json>>newUser.toJson());
    if createResult is error {
        log:printError("Failed to create user in Firestore", createResult);
        json errorResponse = {
            "message": "Failed to create user",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    else {
        io:println("User created successfully with ID: " + documentId);
    }

    // Generate JWT token
    string token = check generateJWTToken(newUser);

    // Remove password from response
    models:User userResponse = {
        id: newUser.id,
        email: newUser.email,
        firstName: newUser.firstName,
        lastName: newUser.lastName,
        phoneNumber: newUser.phoneNumber,
        role: newUser.role,
        password: "",  // Don't send password back
        emailVerified: newUser.emailVerified,
        profileImageUrl: newUser.profileImageUrl,
        createdAt: newUser.createdAt,
        updatedAt: newUser.updatedAt,
        lastLoginAt: newUser.lastLoginAt
    };

    AuthResponse authResponse = {
        token: token,
        user: userResponse,
        message: "User registered successfully"
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload(authResponse.toJson());
    check caller->respond(response);
    log:printInfo("User registered successfully: " + userReg.email);
}

// User login
public function _login(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();
    if payload is error {
        json errorResponse = {
            "message": "Invalid request payload",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    UserLogin|error loginData = payload.cloneWithType(UserLogin);
    if loginData is error {
        json errorResponse = {
            "message": "Invalid request payload format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Validate required fields
    if loginData.email.length() == 0 || loginData.password.length() == 0 {
        json errorResponse = {
            "message": "Email and password are required",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filter = {"email": loginData.email};
    models:User|error user = models:queryUsers("users", filter);
    if user is error {
        json errorResponse = {
            "message": "Invalid email or password",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    // Verify password
    boolean|error passwordValid = verifyPassword(loginData.password, user.password);
    if passwordValid is error || !passwordValid {
        json errorResponse = {
            "message": "Invalid email or password",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Update last login time
    string currentTime = time:utcToString(time:utcNow());
    user.lastLoginAt = currentTime;
    user.updatedAt = currentTime;

    error? updateResult = models:updateDocument("users", loginData.email, <map<json>>user.toJson());
    if updateResult is error {
        log:printError("Failed to update last login time", updateResult);
    }

    // Generate JWT token
    string token = check generateJWTToken(user);

    // Remove password from response
    models:User userResponse = {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        password: "",  // Don't send password back
        emailVerified: user.emailVerified,
        profileImageUrl: user.profileImageUrl,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        lastLoginAt: user.lastLoginAt
    };

    AuthResponse authResponse = {
        token: token,
        user: userResponse,
        message: "Login successful"
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(authResponse.toJson());
    check caller->respond(response);
    log:printInfo("User logged in successfully: " + loginData.email);
}

// Authentication middleware
public function authenticateRequest(http:Request req) returns models:User|error {
    string|http:HeaderNotFoundError authHeader = req.getHeader("Authorization");
    if authHeader is http:HeaderNotFoundError {
        return error("Authorization header not found");
    }

    if !authHeader.startsWith("Bearer ") {
        return error("Invalid authorization header format");
    }

    string token = authHeader.substring(7);
    map<json>|error payload = verifyJWTToken(token);
    if payload is error {
        return error("Invalid token: " + payload.message());
    }

    // Extract user information from token
    json userId = payload["userId"] ?: "";
    json email = payload["email"] ?: "";

    if userId.toString().length() == 0 || email.toString().length() == 0 {
        return error("Invalid token claims");
    }

    // Get full user data from Firestore for verification
    map<json> filter = {"email": email.toString()};
    models:User|error user = models:queryUsers("users", filter);

    if user is error {
        return error("Failed to parse user data");
    }

    return user;
}

// Helper function to extract user ID from token
function extractUserIdFromToken(http:Request req) returns string|error {
    models:User|error user = authenticateRequest(req);
    if user is error {
        return user;
    }
    return user.id;
}

// Role-based authorization middleware
public function authorizeRole(http:Request req, string[] allowedRoles) returns models:User|error {
    models:User|error user = authenticateRequest(req);
    if user is error {
        return user;
    }

    boolean hasRole = false;
    foreach string role in allowedRoles {
        if user.role == role {
            hasRole = true;
            break;
        }
    }

    if !hasRole {
        return error("Insufficient permissions");
    }

    return user;
}

// Get user profile
# Description.
#
# + caller - parameter description  
# + req - parameter description
# + return - return value description
public function getUserProfile(http:Caller caller, http:Request req) returns error? {
    models:User|error user = authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Remove password from response
    models:User userResponse = {
        id: user.id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phoneNumber: user.phoneNumber,
        role: user.role,
        password: "",  // Don't send password back
        emailVerified: user.emailVerified,
        profileImageUrl: user.profileImageUrl,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        lastLoginAt: user.lastLoginAt
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(userResponse.toJson());
    check caller->respond(response);
}

