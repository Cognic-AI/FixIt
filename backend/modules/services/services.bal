import backend.auth;
import backend.mongodb as mongoModule;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Service model types
public type Service record {
    string id;
    string providerId;
    string providerEmail;
    string title;
    string description;
    string category;
    boolean availability;
    decimal price;
    string location;
    string createdAt;
    string updatedAt;
    string tags;
    string images;
};

public type ServiceCreation record {
    string title;
    string description;
    string category;
    decimal price;
    string tags;
    string images;
    string location;
};

// Create a new service (Provider only)
public function createService(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize vendor role
    auth:User|error user = auth:authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can create services",
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

    ServiceCreation|error serviceData = payload.cloneWithType(ServiceCreation);
    if serviceData is error {
        json errorResponse = {
            "message": "Invalid service data format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Create service object
    string serviceId = uuid:createType1AsString();
    string currentTime = time:utcToString(time:utcNow());

    Service newService = {
        id: serviceId,
        providerId: user.id,
        providerEmail: user.email,
        title: serviceData.title,
        description: serviceData.description,
        category: serviceData.category,
        availability: true,
        price: serviceData.price,
        location: serviceData.location,
        createdAt: currentTime,
        updatedAt: currentTime,
        tags: serviceData.tags,
        images: serviceData.images};

    // Save service to Firestore
    string|error createResult = check mongoModule:createDocument("services", mapToJSON(newService.toJson()));
    if createResult is error {
        log:printError("Failed to create service in Firestore", createResult);
        json errorResponse = {
            "message": "Failed to create service",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Service created successfully",
        "service": newService.toJson()
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Service created successfully by provider: " + user.email);
}

public isolated function mapToJSON(json data) returns map<json> {
    if data is map<json> {
        // If it's already a map<json>, just return it
        return data;
    } else if data is json[] {
        // If it's an array, you might want to handle it differently
        // Here I'm converting it to a map with index-based keys
        map<json> result = {};
        int i = 0;
        foreach var item in data {
            result[i.toString()] = item;
            i += 1;
        }
        return result;
    } else {

        // Handle nil case
        io:println("Received nil data, returning empty map");
        return {};
    }
}

// Get all services (Public endpoint, but shows user info if authenticated)
public function getServices(http:Caller caller, http:Request req) returns error? {
    // Optional authentication - show additional info if user is authenticated
    auth:User|error user = auth:authenticateRequest(req);
    boolean isAuthenticated = user is auth:User;
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
    // Get services from Firestore
    map<json> filters = {
        "availability": true // Only fetch active services
};
    Service[]|error servicesData = mongoModule:queryServices(filters);
    if servicesData is error {
        log:printError("Failed to fetch services from Firestore", servicesData);
        json errorResponse = {
            "message": "Failed to fetch services",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload
(errorResponse);
        check caller->respond(response);
        return;
    }

    string userRole = isAuthenticated && user is auth:User ? user.role : "guest";

    json successResponse = {
        "message": "Services retrieved successfully",
        "services": servicesData.toJson(),
        "isAuthenticated": isAuthenticated,
        "userRole": userRole
};

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}

// Get user's own services (Provider only)
public function getMyServices(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize provider role
    auth:User|error user = auth:authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can view their services",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // In a real implementation, you would filter services by provider ID
    // For now, we'll get all services and filter them
    map<json> filters = {
        "providerEmail": user.email // Filter by provider ID
};
    Service[]|error allServicesData = mongoModule:queryServices(filters);
    if allServicesData is error {
        log:printError("Failed to fetch services from MongoDB", allServicesData);
        json errorResponse = {
            "message": "Failed to fetch services",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Your services retrieved successfully",
        "services": allServicesData.toJson(),
        "provider": {
            "id": user.id,
            "email": user.email,
            "firstName": user.firstName,
            "lastName": user.lastName
        }
};

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload
(successResponse);
    check caller->respond(response);
}

// Update service (Provider only, own services)
public function updateService(http:Caller caller, http:Request req, string serviceId) returns error? {
    // Authenticate and authorize vendor role
    auth:User|error user = auth:authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can update services",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get existing service to verify ownership
    map<json> filters = {
        "id": serviceId,
        "providerId": user.id // Ensure the service belongs to the user
    };
    Service|error serviceData = mongoModule:queryService(filters);
    if serviceData is error {
        json errorResponse = {
            "message": "Service not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }
    // Check if user owns the service
    if serviceData.providerId != user.id {
        json errorResponse = {
            "message": "Forbidden: You can only update your own services",
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

    // Update service fields
    serviceData.updatedAt = time:utcToString(time:utcNow());

    if payload.title is string {
        serviceData.title = (check payload.title).toString();
    }
    if payload.description is string {
        serviceData.description = (check payload.description).toString();
    }
    if payload.category is string {
        serviceData.category = (check payload.category).toString();
    }
    if payload.price is decimal {
        serviceData.price = (check payload.price);
    }
    if payload.location is string {
        serviceData.location = (check payload.location).toString();
    }
    if payload.availability is boolean {
        serviceData.availability = check payload.availability;
    }

    // Update service in Firestore
    error? updateResult = mongoModule:updateDocument("services", serviceId, mapToJSON(serviceData.toJson()));
    if updateResult is error {
        log:printError("Failed to update service in Firestore", updateResult);
        json errorResponse = {
            "message": "Failed to update service",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Service updated successfully",
        "service": serviceData.toJson()
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Service updated successfully: " + serviceId);
}

// Delete service (Vendor only, own services)
public function deleteService(http:Caller caller, http:Request req, string serviceId) returns error? {
    // Authenticate and authorize vendor role
    auth:User|error user = auth:authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service vendors can delete services",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get existing service to verify ownership
    map<json> filters = {
        "id": serviceId,
        "providerId": user.id // Ensure the service belongs to the user
    };
    Service|error existingService = mongoModule:queryService(filters);
    if existingService is error {
        json errorResponse = {
            "message": "Service not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Check if user owns the service
    if existingService.providerId != user.id {
        json errorResponse = {
            "message": "Forbidden: You can only delete your own services",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Delete service from Firestore
    error? deleteResult = mongoModule:deleteDocument("services", serviceId);
    if deleteResult is error {
        log:printError("Failed to delete service from Firestore", deleteResult);
        json errorResponse = {
            "message": "Failed to delete service",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Service deleted successfully"
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Service deleted successfully: " + serviceId);
}
