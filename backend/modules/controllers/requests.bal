import backend.models;

import ballerina/http;
import ballerina/io; // Added for io logs
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Service model types
public type Request record {
    string id;
    string serviceId;
    string providerId;
    string clientId;
    string state;
    string location;
    string createdAt;
    string updatedAt;
    string chatId;
};

public type RequestResponse record {
    string id;
    string serviceId;
    string providerId;
    string clientId;
    string state;
    string location;
    string createdAt;
    string updatedAt;
    string chatId;
    string title;
    string description;
    string category;
    boolean availability;
    decimal price;
    string tags;
    string images;
};

public type RequestCreation record {
    string serviceId;
    string clientId;
    string providerId;
};

// Create a new request (Provider only)
public function createRequest(http:Caller caller, http:Request req) returns error? {
    io:println("createRequest called", req.getJsonPayload()); // IO log
    // Authenticate and authorize client role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in createRequest"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only service clients can create requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json|error payload = req.getJsonPayload();
    if payload is error {
        io:println("Invalid request payload in createRequest"); // IO log
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

    RequestCreation|error requestData = payload.cloneWithType(RequestCreation);
    if requestData is error {
        io:println("Invalid request data format in createRequest"); // IO log
        json errorResponse = {
            "message": "Invalid request data format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Create request object
    string requestId = uuid:createType1AsString();
    string currentTime = time:utcToString(time:utcNow());

    Request newRequest = {
        id: requestId,
        serviceId: requestData.serviceId,
        clientId: requestData.clientId,
        providerId: requestData.providerId,
        state: "pending",
        location: "",
        chatId: "",
        createdAt: currentTime,
        updatedAt: currentTime
    };

    io:println("Creating new request with ID: " + requestId); // IO log

    // Save request to Firestore
    string|error createResult = check models:createDocument("requests", mapToJSON(newRequest.toJson()));
    if createResult is error {
        io:println("Failed to create request in Firestore: " + createResult.toString()); // IO log
        log:printError("Failed to create request in Firestore", createResult);
        json errorResponse = {
            "message": "Failed to create request",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload
(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Request created successfully",
        "request": newRequest.toJson()
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload
(successResponse);
    check caller->respond(response);
    io:println("Request created successfully by provider: " + user.email); // IO log
    log:printInfo("Request created successfully by provider: " + user.email);
}

// Get all requests (Public endpoint, but shows user info if authenticated)
public function getRequests(http:Caller caller, http:Request req) returns error? {
    io:println("getRequests called"); // IO log
    // Optional authentication - show additional info if user is authenticated
    models:User|error user = authenticateRequest(req);
    boolean isAuthenticated = user is models:User;
    if user is error && user.message() != "Unauthorized" {
        io:println("Failed to authenticate user in getRequests"); // IO log
        json errorResponse = {
            "message": "Failed to authenticate user",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    // Get requests from Firestore
    map<json> filters = {
    };
    if user is models:User && user.role == "client" {
        filters["clientId"] = user.id; // Filter by client ID if authenticated as client
    }
    else if user is models:User && user.role == "vendor" {
        filters["providerId"] = user.id; // Filter by provider ID if authenticated as vendor
    }
    RequestResponse|error requestsData = check models:queryRequest(filters);
    if requestsData is error {
        io:println("Failed to fetch requests from Firestore: " + requestsData.toString()); // IO log
        log:printError("Failed to fetch requests from Firestore", requestsData);
        json errorResponse = {
            "message": "Failed to fetch requests",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    string userRole = isAuthenticated && user is models:User ? user.role : "guest";

    json successResponse = {
        "message": "Requests retrieved successfully",
        "requests": requestsData.toJson(),
        "isAuthenticated": isAuthenticated,
        "userRole": userRole
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("Requests retrieved successfully. Authenticated: " + isAuthenticated.toString()); // IO log
}

// Get user's own requests (Provider only)
public function getMyRequests(http:Caller caller, http:Request req) returns error? {
    io:println("getMyRequests called"); // IO log
    // Authenticate and authorize provider role
    models:User|error user = authorizeRole(req, ["client", "vendor"]);
    if user is error {
        io:println("Unauthorized access attempt in getMyRequests"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only service clients can view their requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filters = {};
    if user is models:User {
        if user.role == "client" {
            filters["clientId"] = user.id; // Filter by client ID if authenticated as client
        } else if user.role == "vendor" {
            filters["providerId"] = user.id; // Filter by provider ID if authenticated as vendor
        }
    }
    Request[]|error allRequestsData = models:queryRequests(filters);
    if allRequestsData is error {
        io:println("Failed to fetch requests from Firestore: " + allRequestsData.toString()); // IO log
        log:printError("Failed to fetch requests from Firestore", allRequestsData);
        json errorResponse = {
            "message": "Failed to fetch requests",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Your requests retrieved successfully",
        "requests": allRequestsData.toJson(),
        "provider": {
            "id": user.id,
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName
        }
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("User's requests retrieved successfully for provider: " + user.email); // IO log
}

// Update request (Provider only, own requests)
public function updateRequest(http:Caller caller, http:Request req, string requestId) returns error? {
    io:println("updateRequest called for ID: " + requestId); // IO log
    // Authenticate and authorize client role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in updateRequest"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only service clients can update requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get existing request to verify ownership
    map<json> filters = {
        "id": requestId,
        "providerId": user.id // Ensure the request belongs to the user
    };
    Request|error requestData = models:queryRequest(filters);
    if requestData is error {
        io:println("Request not found in updateRequest"); // IO log
        json errorResponse = {
            "message": "Request not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    // Check if user owns the request
    if requestData.providerId != user.id {
        io:println("Forbidden: User does not own the request in updateRequest"); // IO log
        json errorResponse = {
            "message": "Forbidden: You can only update your own requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json|error payload = req.getJsonPayload();
    if payload is error {
        io:println("Invalid request payload in updateRequest"); // IO log
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

    // Update request fields
    requestData.updatedAt = time:utcToString(time:utcNow());

    if payload.serviceId is string {
        requestData.serviceId = (check payload.serviceId).toString();
    }
    if payload.clientId is string {
        requestData.clientId = (check payload.clientId).toString();
    }
    if payload.state is string {
        requestData.state = (check payload.state).toString();
    }
    if payload.chatId is string {
        requestData.chatId = (check payload.chatId).toString();
    }
    // Update request in Firestore
    error? updateResult = models:updateDocument("requests", requestId, mapToJSON(requestData.toJson()));
    if updateResult is error {
        io:println("Failed to update request in Firestore: " + updateResult.toString()); // IO log
        log:printError("Failed to update request in Firestore", updateResult);
        json errorResponse = {
            "message": "Failed to update request",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Request updated successfully",
        "request": requestData.toJson()
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("Request updated successfully: " + requestId); // IO log
    log:printInfo("Request updated successfully: " + requestId);
}

// Delete request (Vendor only, own requests)
public function deleteRequest(http:Caller caller, http:Request req, string requestId) returns error? {
    io:println("deleteRequest called for ID: " + requestId); // IO log
    // Authenticate and authorize vendor role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in deleteRequest"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only service clients can delete requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get existing request to verify ownership
    map<json> filters = {
        "id": requestId,
        "providerId": user.id // Ensure the request belongs to the user
    };
    Request|error existingRequest = models:queryRequest(filters);
    if existingRequest is error {
        io:println("Request not found in deleteRequest"); // IO log
        json errorResponse = {
            "message": "Request not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Check if user owns the request
    if existingRequest.providerId != user.id {
        io:println("Forbidden: User does not own the request in deleteRequest"); // IO log
        json errorResponse = {
            "message": "Forbidden: You can only delete your own requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Delete request from Firestore
    error? deleteResult = models:deleteDocument("requests", requestId);
    if deleteResult is error {
        io:println("Failed to delete request from Firestore: " + deleteResult.toString()); // IO log
        log:printError("Failed to delete request from Firestore", deleteResult);
        json errorResponse = {
            "message": "Failed to delete request",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Request deleted successfully"
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("Request deleted successfully: " + requestId); // IO log
    log:printInfo("Request deleted successfully: " + requestId);
}
