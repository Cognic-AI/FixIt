import backend.ai;
import backend.auth;

// import backend.bookings;
// import backend.events;
// import backend.feedback;
// import backend.firestore;
// import backend.maps;
// import backend.messaging;

// import backend.reviews;
// import backend.services;

import ballerina/http;
// import ballerina/log;
import ballerina/time;

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Authorization", "Content-Type", "ngrok-skip-browser-warning"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"]
    }
}

service /api on new http:Listener(8080) {

    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "healthy",
            "service": "FixIt Backend API",
            "timestamp": time:utcNow(),
            "version": "1.0.0"
        };
    }

    // Authentication routes
    resource function post auth/register(http:Caller caller, http:Request req) returns error? {
        check auth:registerUser(caller, req);
    }

    resource function post auth/login(http:Caller caller, http:Request req) returns error? {
        check auth:login(caller, req);
    }

    // resource function post auth/logout(http:Caller caller, http:Request req) returns error? {
    //     check auth:logoutUser(caller, req);
    // }

    // resource function get auth/profile/[string userId](http:Caller caller, http:Request req) returns error? {
    //     check auth:getUserProfile(caller, req, userId);
    // }

    // Services routes
    // resource function get services(http:Caller caller, http:Request req) returns error? {
    //     check services:getServices(caller, req);
    // }

    // resource function post services(http:Caller caller, http:Request req) returns error? {
    //     check services:createService(caller, req);
    // }

    // resource function get services/[string serviceId](http:Caller caller, http:Request req) returns error? {
    //     check services:getServiceById(caller, req, serviceId);
    // }

    // resource function put services/[string serviceId](http:Caller caller, http:Request req) returns error? {
    //     check services:updateService(caller, req, serviceId);
    // }

    // resource function delete services/[string serviceId](http:Caller caller, http:Request req) returns error? {
    //     check services:deleteService(caller, req, serviceId);
    // }

    // // Events routes
    // resource function get events(http:Caller caller, http:Request req) returns error? {
    //     check events:getEvents(caller, req);
    // }

    // resource function post events(http:Caller caller, http:Request req) returns error? {
    //     check events:createEvent(caller, req);
    // }

    // resource function get events/[string eventId](http:Caller caller, http:Request req) returns error? {
    //     check events:getEventById(caller, req, eventId);
    // }

    // Messaging routes
    // resource function get chats/[string userId](http:Caller caller, http:Request req) returns error? {
    //     check messaging:getUserChats(caller, req, userId);
    // }

    // resource function get chats/[string chatId]/messages(http:Caller caller, http:Request req) returns error? {
    //     check messaging:getChatMessages(caller, req, chatId);
    // }

    // resource function post chats/[string chatId]/messages(http:Caller caller, http:Request req) returns error? {
    //     check messaging:sendMessage(caller, req, chatId);
    // }

    // resource function post chats(http:Caller caller, http:Request req) returns error? {
    //     check messaging:createChat(caller, req);
    // }

    // Bookings routes
    // resource function get bookings/[string userId](http:Caller caller, http:Request req) returns error? {
    //     check bookings:getUserBookings(caller, req, userId);
    // }

    // resource function post bookings(http:Caller caller, http:Request req) returns error? {
    //     check bookings:createBooking(caller, req);
    // }

    // resource function put bookings/[string bookingId](http:Caller caller, http:Request req) returns error? {
    //     check bookings:updateBooking(caller, req, bookingId);
    // }

    // // Reviews routes
    // resource function get reviews/service/[string serviceId](http:Caller caller, http:Request req) returns error? {
    //     check reviews:getServiceReviews(caller, req, serviceId);
    // }

    // resource function post reviews(http:Caller caller, http:Request req) returns error? {
    //     check reviews:createReview(caller, req);
    // }

    // // Feedback routes
    // resource function post feedback(http:Caller caller, http:Request req) returns error? {
    //     check feedback:submitFeedback(caller, req);
    // }

    // resource function get feedback(http:Caller caller, http:Request req) returns error? {
    //     check feedback:getFeedback(caller, req);
    // }

    // AI Assistant routes
    isolated resource function post ai/chat(http:Caller caller, http:Request req) returns error? {
        check ai:chatWithGemini(caller, req);
    }

    // resource function post ai/recommendations(http:Caller caller, http:Request req) returns error? {
    //     check ai:getRecommendations(caller, req);
    // }

    // // Maps routes
    // resource function get maps/geocode(http:Caller caller, http:Request req) returns error? {
    //     check maps:geocodeAddress(caller, req);
    // }

    // resource function get maps/directions(http:Caller caller, http:Request req) returns error? {
    //     check maps:getDirections(caller, req);
    // }

    // resource function get maps/nearby(http:Caller caller, http:Request req) returns error? {
    //     check maps:getNearbyPlaces(caller, req);
    // }
}
