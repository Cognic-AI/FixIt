import backend.utils;

import ballerina/io;
import ballerinax/mongodb;

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

public function queryRequest(map<json> filter) returns RequestResponse|error {
    string collection = "requests";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);
    mongodb:Collection mongoCollectionRequests = check db->getCollection("services");

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with User type projection
    Request|mongodb:Error|() result = mongoCollection->findOne(
                    filter,
                    {},  // findOptions
                    (),  // projection
                    Request
                    );

    // Handle the different result cases
    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    } else if result is () {
        io:println("❌ No document found matching the filter");
        return error("User not found");
    }
    else {
        map<json> filter2 = {"id": result.serviceId};

        RequestResponse|error?|mongodb:DatabaseError|mongodb:ApplicationError res = mongoCollectionRequests->findOne(
        filter2,
        {},  // findOptions
        (),  // projection
        RequestResponse
        );
        if res is mongodb:ApplicationError {
            io:println("❌ Error executing query: ", res.message());
            return error("MongoDB error: " + res.message());
        } else if res is error {
            io:println("❌ Error retrieving service details: ", res.message());
            return error("Service details retrieval error: " + res.message());
        } else if res is RequestResponse {
            // Create a new RequestResponse with service details
            RequestResponse result_ = {
                id: result.id,
                serviceId: result.serviceId,
                providerId: result.providerId,
                clientId: result.clientId,
                state: result.state,
                location: result.location,
                createdAt: result.createdAt,
                updatedAt: result.updatedAt,
                chatId: result.chatId,
                title: res.title,
                description: res.description,
                category: res.category,
                availability: res.availability,
                price: res.price,
                tags: res.tags,
                images: res.images
            };
            io:println("✅ User document retrieved successfully");
            return result_;
        }
        return error("Unexpected result type");
    }
}

public function queryRequestForStatusUpdate(map<json> filter) returns Request|error {
    string collection = "requests";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with User type projection
    Request|mongodb:Error|() result = mongoCollection->findOne(
                    filter,
                    {},  // findOptions
                    (),  // projection
                    Request
                    );

    // Handle the different result cases
    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    } else if result is () {
        io:println("❌ No document found matching the filter");
        return error("User not found");
    }
    else {
        return result;
    }
}

public function queryRequests(map<json> filter) returns RequestResponse[]|error {
    string collection = "requests";

    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);
    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with Request type projection
    stream<Request, error?>|mongodb:Error result = mongoCollection->find(
        filter,
        {},  // findOptions
        (),  // projection
        Request
    );

    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    }

    RequestResponse[] requests = [];

    if result is stream<Request, error?> {
        error? streamError = result.forEach(function(Request req) {
            io:println("🔍 Querying service details for request ID: ", req.id);

            if req.serviceId == "" {
                io:println("⚠️ Request with ID ", req.id, " has no associated service ID");
                return;
            }

            map<json> serviceFilter = {};
            _Service|error res = queryService(serviceFilter);

            if res is error {
                io:println("❌ Error retrieving service details: ", res.message());
            } else if res is _Service {
                RequestResponse requestResponse = {
                    id: req.id,
                    serviceId: req.serviceId,
                    providerId: req.providerId,
                    clientId: req.clientId,
                    state: req.state,
                    location: req.location,
                    createdAt: req.createdAt,
                    updatedAt: req.updatedAt,
                    chatId: req.chatId,
                    title: res.title,
                    description: res.description,
                    category: res.category,
                    availability: res.availability,
                    price: res.price,
                    tags: res.tags,
                    images: res.images
                };
                requests.push(requestResponse);
                io:println("✅ Request with ID ", req.id, " processed successfully");
            }
        });

        if streamError is error {
            io:println("❌ Error processing stream: ", streamError.message());
            return error("Stream processing error: " + streamError.message());
        }
    }

    if requests.length() == 0 {
        io:println("⚠️ No documents found matching the filter");
        return [];
    }
    io:println("✅ Retrieved ", requests.length(), " requests successfully");
    return requests;
}
