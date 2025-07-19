import ballerina/io;
import ballerinax/mongodb;
import backend.utils;

public type User record {
    string id;
    string email;
    string firstName;
    string lastName;
    string? phoneNumber;
    string location; // New field for location
    string role; // "customer", "provider", "admin"
    string password; // hashed
    boolean emailVerified;
    string? profileImageUrl;
    string createdAt;
    string updatedAt;
    string? lastLoginAt;
}; // Initialize MongoDB client

public function queryUsers(
        string collection,
        map<json> filter
) returns User|error {
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query with User type projection
    User|mongodb:Error|() result = mongoCollection->findOne(
        filter,
        {},  // findOptions
        (),  // projection
        User
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