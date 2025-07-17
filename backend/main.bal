import backend.controllers;
import backend.models;

// import backend.bookings;
// import backend.services;

// import backend.events;
// import backend.feedback;
// import backend.firestore;
// import backend.maps;
// import backend.messaging;

// import backend.reviews;

import ballerina/http;
// import ballerina/log;
import ballerina/time;

// Shared CORS configuration
final http:CorsConfig corsConfig = {
    allowOrigins: ["*"],
    allowCredentials: false,
    allowHeaders: ["CORELATION_ID", "Authorization", "Content-Type", "ngrok-skip-browser-warning"],
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"]
};

// Base health check service
@http:ServiceConfig {
        cors: corsConfig
}
isolated service /api on new http:Listener(8083) {
    resource function get health() returns json {
        return {
            "status": "healthy",
            "service": "FixIt Backend API",
            "timestamp": time:utcNow(),
            "version": "1.0.0"
        };
    }
}

// Authentication service
@http:ServiceConfig {
    cors: corsConfig
}
isolated service /api/auth on new http:Listener(8080) {
    resource function post register(http:Caller caller, http:Request req) returns error? {
        check controllers:_registerUser(caller, req);
    }

    resource function post login(http:Caller caller, http:Request req) returns error? {
        check controllers:_login(caller, req);
    }

    resource function get profile(http:Caller caller, http:Request req) returns error? {
        check controllers:getUserProfile(caller, req);
    }

    resource function get test(http:Caller caller, http:Request req) returns error? {
        models:User|error user = controllers:authenticateRequest(req);
        if user is error {
            json errorResponse = {
                "message": "Unauthorized: " + user.message(),
                "statusCode": 401
            };
            http:Response response = new;
            response.statusCode = 401;
            response.setJsonPayload(errorResponse);
            check caller->respond(response);
            return;
        }

        json successResponse = {
            "message": "Authentication successful",
            "user": {
                "id": user.id,
                "email": user.email,
                "role": user.role,
                "firstName": user.firstName,
                "lastName": user.lastName
            }
        };

        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload(successResponse);
        check caller->respond(response);
    }
}

// Admin service
@http:ServiceConfig {
    cors: corsConfig
}
isolated service /api/admin on new http:Listener(8081) {
    resource function get users(http:Caller caller, http:Request req) returns error? {
        models:User|error user = controllers:authorizeRole(req, ["admin"]);
        if user is error {
            json errorResponse = {
                "message": "Forbidden: " + user.message(),
                "statusCode": 403
            };
            http:Response response = new;
            response.statusCode = 403;
            response.setJsonPayload(errorResponse);
            check caller->respond(response);
            return;
        }

        json successResponse = {
            "message": "Admin access granted",
            "adminUser": user.email
        };

        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload(successResponse);
        check caller->respond(response);
    }
}

// AI service
@http:ServiceConfig {
    cors: corsConfig
}
isolated service /api/ai on new http:Listener(8082) {
    resource function post chat(http:Caller caller, http:Request req) returns error? {
        check controllers:chatWithGemini(caller, req);
    }

    // resource function post recommendations(http:Caller caller, http:Request req) returns error? {
    //     check ai:getRecommendations(caller, req);
    // }
}

// Services
@http:ServiceConfig {
        cors: corsConfig
}
isolated service /api/services on new http:Listener(8084) {
    resource function get .(http:Caller caller, http:Request req) returns error? {
        check controllers:getServices(caller, req);
    }

    resource function post .(http:Caller caller, http:Request req) returns error? {
        check controllers:createService(caller, req);
    }

    resource function get my(http:Caller caller, http:Request req) returns error? {
        check controllers:getMyServices(caller, req);
    }

    resource function put [string serviceId](http:Caller caller, http:Request req) returns error? {
        check controllers:updateService(caller, req, serviceId);
    }

    resource function delete [string serviceId](http:Caller caller, http:Request req) returns error? {
        check controllers:deleteService(caller, req, serviceId);
    }
}

// Events service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/events on new http:Listener(8080) {
//     resource function get .(http:Caller caller, http:Request req) returns error? {
//         check events:getEvents(caller, req);
//     }

//     resource function post .(http:Caller caller, http:Request req) returns error? {
//         check events:createEvent(caller, req);
//     }

//     resource function get [string eventId](http:Caller caller, http:Request req) returns error? {
//         check events:getEventById(caller, req, eventId);
//     }
// }

// Messaging service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/chats on new http:Listener(8080) {
//     resource function get [string userId](http:Caller caller, http:Request req) returns error? {
//         check messaging:getUserChats(caller, req, userId);
//     }

//     resource function get [string chatId]/messages(http:Caller caller, http:Request req) returns error? {
//         check messaging:getChatMessages(caller, req, chatId);
//     }

//     resource function post [string chatId]/messages(http:Caller caller, http:Request req) returns error? {
//         check messaging:sendMessage(caller, req, chatId);
//     }

//     resource function post .(http:Caller caller, http:Request req) returns error? {
//         check messaging:createChat(caller, req);
//     }
// }

// Bookings service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/bookings on new http:Listener(8080) {
//     resource function get [string userId](http:Caller caller, http:Request req) returns error? {
//         check bookings:getUserBookings(caller, req, userId);
//     }

//     resource function post .(http:Caller caller, http:Request req) returns error? {
//         check bookings:createBooking(caller, req);
//     }

//     resource function put [string bookingId](http:Caller caller, http:Request req) returns error? {
//         check bookings:updateBooking(caller, req, bookingId);
//     }
// }

// Reviews service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/reviews on new http:Listener(8080) {
//     resource function get service/[string serviceId](http:Caller caller, http:Request req) returns error? {
//         check reviews:getServiceReviews(caller, req, serviceId);
//     }

//     resource function post .(http:Caller caller, http:Request req) returns error? {
//         check reviews:createReview(caller, req);
//     }
// }

// Feedback service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/feedback on new http:Listener(8080) {
//     resource function post .(http:Caller caller, http:Request req) returns error? {
//         check feedback:submitFeedback(caller, req);
//     }

//     resource function get .(http:Caller caller, http:Request req) returns error? {
//         check feedback:getFeedback(caller, req);
//     }
// }

// Maps service (commented out)
// @http:ServiceConfig {
//     cors: corsConfig
// }
// isolated service /api/maps on new http:Listener(8080) {
//     resource function get geocode(http:Caller caller, http:Request req) returns error? {
//         check maps:geocodeAddress(caller, req);
//     }

//     resource function get directions(http:Caller caller, http:Request req) returns error? {
//         check maps:getDirections(caller, req);
//     }

//     resource function get nearby(http:Caller caller, http:Request req) returns error? {
//         check maps:getNearbyPlaces(caller, req);
//     }
// }