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

public function queryRequest(map<json> filter) returns Request|error {
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

        io:println("✅ User document retrieved successfully");
        return result;
    }

}

public function queryRequests(map<json> filter) returns Request[]|error {
    string collection = "requests";

    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with Service type projection
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

    // Convert stream to array
    Request[] requests = [];
    error? e = result.forEach(function(Request 'request) {
        requests.push('request);
    });

    if e is error {
        io:println("❌ Error processing stream: ", e.message());
        return error("Stream processing error: " + e.message());
    }

    if requests.length() == 0 {
        io:println("⚠️ No documents found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", requests.length(), " requests successfully");
    return requests;
}

