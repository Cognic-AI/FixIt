// import backend.auth;
// import backend.firestore as firestoreModule;

// import ballerina/http;
// import ballerina/log;
// import ballerina/time;
// import ballerina/uuid;

// // Service model types
// public type Service record {
//     string id;
//     string providerId;
//     string providerEmail;
//     string title;
//     string description;
//     string category;
//     decimal price;
//     string[] tags;
//     boolean isActive;
//     string[] images;
//     string location;
//     string createdAt;
//     string updatedAt;
// };

// public type ServiceCreation record {
//     string title;
//     string description;
//     string category;
//     decimal price;
//     string[] tags;
//     string[] images;
//     string location;
// };

// // Create a new service (Provider only)
// public isolated function createService(http:Caller caller, http:Request req) returns error? {
//     // Authenticate and authorize provider role
//     auth:User|error user = auth:authorizeRole(req, ["provider"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only service providers can create services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

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

//     ServiceCreation|error serviceData = payload.cloneWithType(ServiceCreation);
//     if serviceData is error {
//         json errorResponse = {
//             "message": "Invalid service data format",
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Create service object
//     string serviceId = uuid:createType1AsString();
//     string currentTime = time:utcToString(time:utcNow());

//     Service newService = {
//         id: serviceId,
//         providerId: user.id,
//         providerEmail: user.email,
//         title: serviceData.title,
//         description: serviceData.description,
//         category: serviceData.category,
//         price: serviceData.price,
//         tags: serviceData.tags,
//         isActive: true,
//         images: serviceData.images,
//         location: serviceData.location,
//         createdAt: currentTime,
//         updatedAt: currentTime
//     };

//     // Save service to Firestore
//     error? createResult = firestoreModule:createDocument("services", serviceId, newService.toJson());
//     if createResult is error {
//         log:printError("Failed to create service in Firestore", createResult);
//         json errorResponse = {
//             "message": "Failed to create service",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Service created successfully",
//         "service": newService.toJson()
//     };

//     http:Response response = new;
//     response.statusCode = 201;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Service created successfully by provider: " + user.email);
// }

// // Get all services (Public endpoint, but shows user info if authenticated)
// public isolated function getServices(http:Caller caller, http:Request req) returns error? {
//     // Optional authentication - show additional info if user is authenticated
//     auth:User|error user = auth:authenticateRequest(req);
//     boolean isAuthenticated = user is auth:User;

//     // Get services from Firestore
//     json[]|error servicesData = firestoreModule:getDocuments("services");
//     if servicesData is error {
//         log:printError("Failed to fetch services from Firestore", servicesData);
//         json errorResponse = {
//             "message": "Failed to fetch services",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Services retrieved successfully",
//         "services": servicesData,
//         "isAuthenticated": isAuthenticated,
//         "userRole": isAuthenticated ? (user as auth:User).role: null
// };

// http:Response response = new;
// response .statusCode = 200;
// response.setJsonPayload
// (successResponse) ;
// check caller->respond(response);
// }

// // Get user's own services (Provider only)
// public isolated function getMyServices(http:Caller caller, http:Request req) returns error? {
//     // Authenticate and authorize provider role
//     auth:User|error user = auth:authorizeRole(req, ["provider"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only service providers can view their services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // In a real implementation, you would filter services by provider ID
//     // For now, we'll get all services and filter them
//     json[]|error allServicesData = firestoreModule:getDocuments("services");
//     if allServicesData is error {
//         log:printError("Failed to fetch services from Firestore", allServicesData);
//         json errorResponse = {
//             "message": "Failed to fetch services",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Filter services by provider ID (simplified filtering)
//     json[] userServices = [];
//     foreach json serviceJson in allServicesData {
//         Service|error service = serviceJson.cloneWithType(Service);
//         if service is Service && service.providerId == user.id {
//             userServices.push(serviceJson);
//         }
//     }

//     json successResponse = {
//         "message": "Your services retrieved successfully",
//         "services": userServices,
//         "provider": {
//             "id": user.id,
//             "email": user.email,
//             "firstName": user.firstName,
//             "lastName": user.lastName
//         }
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
// }

// // Update service (Provider only, own services)
// public isolated function updateService(http:Caller caller, http:Request req, string serviceId) returns error? {
//     // Authenticate and authorize provider role
//     auth:User|error user = auth:authorizeRole(req, ["provider"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only service providers can update services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get existing service to verify ownership
//     json|error serviceData = firestoreModule:getDocument("services", serviceId);
//     if serviceData is error {
//         json errorResponse = {
//             "message": "Service not found",
//             "statusCode": 404
//         };
//         http:Response response = new;
//         response.statusCode = 404;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     Service|error existingService = serviceData.cloneWithType(Service);
//     if existingService is error {
//         json errorResponse = {
//             "message": "Invalid service data",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Check if user owns the service
//     if existingService.providerId != user.id {
//         json errorResponse = {
//             "message": "Forbidden: You can only update your own services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

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

//     // Update service fields
//     existingService.updatedAt = time:utcToString(time:utcNow());

//     if payload.title is string {
//         existingService.title = payload.title.toString();
//     }
//     if payload.description is string {
//         existingService.description = payload.description.toString();
//     }
//     if payload.category is string {
//         existingService.category = payload.category.toString();
//     }
//     if payload.price is decimal {
//         existingService.price = <decimal>payload.price;
//     }
//     if payload.location is string {
//         existingService.location = payload.location.toString();
//     }
//     if payload.isActive is boolean {
//         existingService.isActive = <boolean>payload.isActive;
//     }

//     // Update service in Firestore
//     error? updateResult = firestoreModule:updateDocument("services", serviceId, existingService.toJson());
//     if updateResult is error {
//         log:printError("Failed to update service in Firestore", updateResult);
//         json errorResponse = {
//             "message": "Failed to update service",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Service updated successfully",
//         "service": existingService.toJson()
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Service updated successfully: " + serviceId);
// }

// // Delete service (Provider only, own services)
// public isolated function deleteService(http:Caller caller, http:Request req, string serviceId) returns error? {
//     // Authenticate and authorize provider role
//     auth:User|error user = auth:authorizeRole(req, ["provider"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only service providers can delete services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get existing service to verify ownership
//     json|error serviceData = firestoreModule:getDocument("services", serviceId);
//     if serviceData is error {
//         json errorResponse = {
//             "message": "Service not found",
//             "statusCode": 404
//         };
//         http:Response response = new;
//         response.statusCode = 404;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     Service|error existingService = serviceData.cloneWithType(Service);
//     if existingService is error {
//         json errorResponse = {
//             "message": "Invalid service data",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Check if user owns the service
//     if existingService.providerId != user.id {
//         json errorResponse = {
//             "message": "Forbidden: You can only delete your own services",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Delete service from Firestore
//     error? deleteResult = firestoreModule:deleteDocument("services", serviceId);
//     if deleteResult is error {
//         log:printError("Failed to delete service from Firestore", deleteResult);
//         json errorResponse = {
//             "message": "Failed to delete service",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Service deleted successfully"
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Service deleted successfully: " + serviceId);
// }
