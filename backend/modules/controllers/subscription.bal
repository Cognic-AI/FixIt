import backend.models;

import ballerina/http;
import ballerina/io; // Added for io logs
import ballerina/log;
import ballerina/uuid;

public type serviceSubscription record {
    string serviceId;
};

public type serviceSubscriptionDelete record {
    string id;
    string serviceId;
};

public type serviceSubscriptionResponse record {
    string id;
    string serviceId;
    string clientId;
};

// Create a new request (Provider only)
public function saveServiceSubscription(http:Caller caller, http:Request req) returns error? {
    io:println("saveServiceSubscription called", req.getJsonPayload()); // IO log
    // Authenticate and authorize client role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in saveServiceSubscription"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only service clients can save subscriptions",
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
        io:println("Invalid request payload in saveServiceSubscription"); // IO log
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

    serviceSubscription|error requestData = payload.cloneWithType(serviceSubscription);
    if requestData is error {
        io:println("Invalid request data format in saveServiceSubscription"); // IO log
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
    string subscriptionId = uuid:createType1AsString();

    serviceSubscriptionResponse newSubscription = {
        id: subscriptionId,
        serviceId: requestData.serviceId,
        clientId: user.id
    };

    io:println("Creating new subscription with ID: " + subscriptionId); // IO log

    // Save subscription to Firestore
    string|error createResult = check models:createDocument("subscriptions", mapToJSON(newSubscription.toJson()));
    if createResult is error {
        io:println("Failed to create subscription in Firestore: " + createResult.toString()); // IO log
        log:printError("Failed to create subscription in Firestore", createResult);
        json errorResponse = {
            "message": "Failed to create subscription",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Subscription created successfully",
        "subscription": newSubscription.toJson()
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Subscription created successfully");
}

// Get user's own subscriptions (Client or Vendor)
public function getMySubscriptions(http:Caller caller, http:Request req) returns error? {
    io:println("getMySubscriptions called"); // IO log
    // Authenticate and authorize roles
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in getMySubscriptions"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only clients and vendors can view their subscriptions",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filters = {
        "clientId": user.id
    };

    serviceSubscriptionResponse[]|error allSubscriptions = models:querySubscriptions(filters);
    if allSubscriptions is error {
        io:println("Failed to fetch subscriptions from Firestore: " + allSubscriptions.toString()); // IO log
        log:printError("Failed to fetch subscriptions from Firestore", allSubscriptions);
        json errorResponse = {
            "message": "Failed to fetch subscriptions",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Your subscriptions retrieved successfully",
        "subscriptions": allSubscriptions.toJson()
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("User's subscriptions retrieved successfully."); // IO log
}

// Delete subscription (Client only, own subscriptions)
public function deleteServiceSubscription(http:Caller caller, http:Request req) returns error? {
    io:println("deleteServiceSubscription"); // IO log
    // Authenticate and authorize client role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        io:println("Unauthorized access attempt in deleteServiceSubscription"); // IO log
        json errorResponse = {
            "message": "Unauthorized: Only clients can delete subscriptions",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    io:println("User authenticated successfully in deleteServiceSubscription"); // IO log
    json|error payload = req.getJsonPayload();
    if payload is error {
        io:println("Failed to parse JSON payload in deleteServiceSubscription"); // IO log
        json errorResponse = {
            "message": "Invalid JSON payload",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    io:println("JSON payload parsed successfully in deleteServiceSubscription"); // IO log
    serviceSubscriptionDelete|error requestData = payload.cloneWithType(serviceSubscriptionDelete);
    if requestData is error {
        io:println("Invalid request data format in deleteServiceSubscription"); // IO log
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
    io:println("Request data validated successfully in deleteServiceSubscription"); // IO log
    map<json> filter = {
        "serviceId": requestData.serviceId,
        "clientId": user.id
    };

    // Get existing subscription to verify ownership
    serviceSubscriptionResponse[]|error existingSubscription = models:querySubscriptions(filter);
    if existingSubscription is error {
        io:println("Subscription not found in deleteServiceSubscription"); // IO log
        json errorResponse = {
            "message": "Subscription not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    io:println("Existing subscription found in deleteServiceSubscription"); // IO log
    // Check if user owns the subscription
    string clientId = existingSubscription[0].clientId;
    if clientId != user.id {
        io:println("Forbidden: User does not own the subscription"); // IO log
        json errorResponse = {
            "message": "Forbidden: You can only delete your own subscriptions",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    io:println("User owns the subscription, proceeding to delete"); // IO log
    // Delete subscription from Firestore
    error? deleteResult = models:deleteDocument("subscriptions", requestData.id);
    if deleteResult is error {
        io:println("Failed to delete subscription from Firestore: " + deleteResult.toString()); // IO log
        log:printError("Failed to delete subscription from Firestore", deleteResult);
        json errorResponse = {
            "message": "Failed to delete subscription",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    io:println("Subscription deleted successfully from Firestore"); // IO log
    json successResponse = {
        "message": "Subscription deleted successfully"
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    io:println("Subscription deleted successfully."); // IO log
    log:printInfo("Subscription deleted successfully.");
}
