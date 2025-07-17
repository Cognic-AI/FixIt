import backend.models;

import ballerina/http;
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

public type RequestCreation record {
    string serviceId;
    string clientId;
    string providerId;
};

// Create a new request (Provider only)
public function createRequest(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize vendor role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can create requests",
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

    // Save request to Firestore
    string|error createResult = check models:createDocument("requests", mapToJSON(newRequest.toJson()));
    if createResult is error {
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
    log:printInfo("Request created successfully by provider: " + user.email);
}

// Get all requests (Public endpoint, but shows user info if authenticated)
public function getRequests(http:Caller caller, http:Request req) returns error? {
    // Optional authentication - show additional info if user is authenticated
    models:User|error user = authenticateRequest(req);
    boolean isAuthenticated = user is models:User;
    if user is error && user.message() != "Unauthorized" {
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
        "availability": true // Only fetch active requests
    };
    Request[]|error requestsData = check models:queryRequests(filters);
    if requestsData is error {
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
}

// Get user's own requests (Provider only)
public function getMyRequests(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize provider role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can view their requests",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Filter requests by provider ID
    map<json> filters = {
        "providerEmail": user.email // Filter by provider email
    };
    Request[]|error allRequestsData = models:queryRequests(filters);
    if allRequestsData is error {
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
}

// Update request (Provider only, own requests)
public function updateRequest(http:Caller caller, http:Request req, string requestId) returns error? {
    // Authenticate and authorize vendor role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can update requests",
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
    log:printInfo("Request updated successfully: " + requestId);
}

// Delete request (Vendor only, own requests)
public function deleteRequest(http:Caller caller, http:Request req, string requestId) returns error? {
    // Authenticate and authorize vendor role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can delete requests",
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
    log:printInfo("Request deleted successfully: " + requestId);
}
