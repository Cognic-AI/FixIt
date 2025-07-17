import ballerina/io;
import ballerinax/mongodb;
import backend.utils;
public type _Service record {
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


public function queryService(map<json> filter) returns _Service|error {
    string collection = "services";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with User type projection
    _Service|mongodb:Error|() result = mongoCollection->findOne(
        filter,
        {},  // findOptions
        (),  // projection
        _Service
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

public function queryServices(map<json> filter) returns _Service[]|error {
    string collection = "services";

    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with Service type projection
    stream<_Service, error?>|mongodb:Error result = mongoCollection->find(
        filter,
        {},  // findOptions
        (),  // projection
        _Service
    );

    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    }

    // Convert stream to array
    _Service[] services = [];
    error? e = result.forEach(function(_Service 'service) {
        services.push('service);
    });

    if e is error {
        io:println("❌ Error processing stream: ", e.message());
        return error("Stream processing error: " + e.message());
    }

    if services.length() == 0 {
        io:println("⚠️ No documents found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", services.length(), " services successfully");
    return services;
}

