// import backend.auth;
// import backend.firestore as firestoreModule;

// import ballerina/http;
// import ballerina/log;
// import ballerina/time;
// import ballerina/uuid;

// // Booking model types
// public type Booking record {
//     string id;
//     string customerId;
//     string customerEmail;
//     string providerId;
//     string providerEmail;
//     string serviceId;
//     string serviceTitle;
//     string status; // "pending", "confirmed", "in_progress", "completed", "cancelled"
//     string scheduledDate;
//     string scheduledTime;
//     decimal price;
//     string location;
//     string? notes;
//     string createdAt;
//     string updatedAt;
// };

// public type BookingCreation record {
//     string serviceId;
//     string scheduledDate;
//     string scheduledTime;
//     string location;
//     string? notes;
// };

// // Create a new booking (Customer only)
// public isolated function createBooking(http:Caller caller, http:Request req) returns error? {
//     // Authenticate and authorize customer role
//     auth:User|error user = auth:authorizeRole(req, ["customer"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only customers can create bookings",
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

//     BookingCreation|error bookingData = payload.cloneWithType(BookingCreation);
//     if bookingData is error {
//         json errorResponse = {
//             "message": "Invalid booking data format",
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get service details to validate it exists and get provider info
//     json|error serviceData = firestoreModule:getDocument("services", bookingData.serviceId);
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

//     // Extract service info
//     json serviceTitle = serviceData.title ?: "Unknown Service";
//     json providerId = serviceData.providerId ?: "";
//     json providerEmail = serviceData.providerEmail ?: "";
//     json servicePrice = serviceData.price ?: 0.0;

//     // Create booking object
//     string bookingId = uuid:createType1AsString();
//     string currentTime = time:utcToString(time:utcNow());

//     Booking newBooking = {
//         id: bookingId,
//         customerId: user.id,
//         customerEmail: user.email,
//         providerId: providerId.toString(),
//         providerEmail: providerEmail.toString(),
//         serviceId: bookingData.serviceId,
//         serviceTitle: serviceTitle.toString(),
//         status: "pending",
//         scheduledDate: bookingData.scheduledDate,
//         scheduledTime: bookingData.scheduledTime,
//         price: <decimal>servicePrice,
//         location: bookingData.location,
//         notes: bookingData.notes,
//         createdAt: currentTime,
//         updatedAt: currentTime
//     };

//     // Save booking to Firestore
//     error? createResult = firestoreModule:createDocument("bookings", bookingId, newBooking.toJson());
//     if createResult is error {
//         log:printError("Failed to create booking in Firestore", createResult);
//         json errorResponse = {
//             "message": "Failed to create booking",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Booking created successfully",
//         "booking": newBooking.toJson()
//     };

//     http:Response response = new;
//     response.statusCode = 201;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Booking created successfully by customer: " + user.email);
// }

// // Get user's bookings (Customer gets their bookings, Provider gets bookings for their services)
// public isolated function getMyBookings(http:Caller caller, http:Request req) returns error? {
//     // Authenticate user
//     auth:User|error user = auth:authenticateRequest(req);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Authentication required",
//             "statusCode": 401
//         };
//         http:Response response = new;
//         response.statusCode = 401;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get all bookings and filter based on user role
//     json[]|error allBookingsData = firestoreModule:getDocuments("bookings");
//     if allBookingsData is error {
//         log:printError("Failed to fetch bookings from Firestore", allBookingsData);
//         json errorResponse = {
//             "message": "Failed to fetch bookings",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Filter bookings based on user role
//     json[] userBookings = [];
//     foreach json bookingJson in allBookingsData {
//         Booking|error booking = bookingJson.cloneWithType(Booking);
//         if booking is Booking {
//             if (user.role == "customer" && booking.customerId == user.id) ||
//                 (user.role == "provider" && booking.providerId == user.id) {
//                 userBookings.push(bookingJson);
//             }
//         }
//     }

//     json successResponse = {
//         "message": "Bookings retrieved successfully",
//         "bookings": userBookings,
//         "userRole": user.role
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
// }

// // Update booking status (Provider only, for their services)
// public isolated function updateBookingStatus(http:Caller caller, http:Request req, string bookingId) returns error? {
//     // Authenticate and authorize provider role
//     auth:User|error user = auth:authorizeRole(req, ["provider"]);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Only providers can update booking status",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get existing booking to verify ownership
//     json|error bookingData = firestoreModule:getDocument("bookings", bookingId);
//     if bookingData is error {
//         json errorResponse = {
//             "message": "Booking not found",
//             "statusCode": 404
//         };
//         http:Response response = new;
//         response.statusCode = 404;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     Booking|error existingBooking = bookingData.cloneWithType(Booking);
//     if existingBooking is error {
//         json errorResponse = {
//             "message": "Invalid booking data",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Check if user is the provider for this booking
//     if existingBooking.providerId != user.id {
//         json errorResponse = {
//             "message": "Forbidden: You can only update bookings for your services",
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

//     json status = payload.status ?: "";
//     string[] validStatuses = ["pending", "confirmed", "in_progress", "completed", "cancelled"];

//     boolean isValidStatus = false;
//     foreach string validStatus in validStatuses {
//         if status.toString() == validStatus {
//             isValidStatus = true;
//             break;
//         }
//     }

//     if !isValidStatus {
//         json errorResponse = {
//             "message": "Invalid status. Valid statuses: " + string:join        (", " , ...validStatuses ),
//             "statusCode"        : 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Update booking status
//     existingBooking.status = status.toString();
//     existingBooking.updatedAt = time:utcToString(time:utcNow());

//     // Update booking in Firestore
//     error? updateResult = firestoreModule:updateDocument("bookings", bookingId, existingBooking.toJson());
//     if updateResult is error {
//         log:printError("Failed to update booking in Firestore", updateResult);
//         json errorResponse = {
//             "message": "Failed to update booking",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Booking status updated successfully",
//         "booking": existingBooking.toJson()
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Booking status updated successfully: " + bookingId);
// }

// // Cancel booking (Customer can cancel their own bookings)
// public isolated function cancelBooking(http:Caller caller, http:Request req, string bookingId) returns error? {
//     // Authenticate user
//     auth:User|error user = auth:authenticateRequest(req);
//     if user is error {
//         json errorResponse = {
//             "message": "Unauthorized: Authentication required",
//             "statusCode": 401
//         };
//         http:Response response = new;
//         response.statusCode = 401;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Get existing booking to verify ownership
//     json|error bookingData = firestoreModule:getDocument("bookings", bookingId);
//     if bookingData is error {
//         json errorResponse = {
//             "message": "Booking not found",
//             "statusCode": 404
//         };
//         http:Response response = new;
//         response.statusCode = 404;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     Booking|error existingBooking = bookingData.cloneWithType(Booking);
//     if existingBooking is error {
//         json errorResponse = {
//             "message": "Invalid booking data",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Check if user is the customer for this booking
//     if existingBooking.customerId != user.id {
//         json errorResponse = {
//             "message": "Forbidden: You can only cancel your own bookings",
//             "statusCode": 403
//         };
//         http:Response response = new;
//         response.statusCode = 403;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Check if booking can be cancelled
//     if existingBooking.status == "completed" || existingBooking.status == "cancelled" {
//         json errorResponse = {
//             "message": "Cannot cancel a booking that is already " + existingBooking.status,
//             "statusCode": 400
//         };
//         http:Response response = new;
//         response.statusCode = 400;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     // Update booking status to cancelled
//     existingBooking.status = "cancelled";
//     existingBooking.updatedAt = time:utcToString(time:utcNow());

//     // Update booking in Firestore
//     error? updateResult = firestoreModule:updateDocument("bookings", bookingId, existingBooking.toJson());
//     if updateResult is error {
//         log:printError("Failed to cancel booking in Firestore", updateResult);
//         json errorResponse = {
//             "message": "Failed to cancel booking",
//             "statusCode": 500
//         };
//         http:Response response = new;
//         response.statusCode = 500;
//         response.setJsonPayload(errorResponse);
//         check caller->respond(response);
//         return;
//     }

//     json successResponse = {
//         "message": "Booking cancelled successfully",
//         "booking": existingBooking.toJson()
//     };

//     http:Response response = new;
//     response.statusCode = 200;
//     response.setJsonPayload(successResponse);
//     check caller->respond(response);
//     log:printInfo("Booking cancelled successfully: " + bookingId);
// }
