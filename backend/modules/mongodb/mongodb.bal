import ballerina/io;
import ballerinax/mongodb;

// MongoDB configuration
configurable string connectionString = ?;
configurable string mongoHost = ?;
configurable int mongoPort = 27017;
configurable string mongoUsername = ?;
configurable string mongoPassword = ?;
configurable string mongoAuthSource = "admin"; // Default admin database for authentication

public type User record {
    string id;
    string email;
    string firstName;
    string lastName;
    string? phoneNumber;
    string role; // "customer", "provider", "admin"
    string password; // hashed
    boolean emailVerified;
    string? profileImageUrl;
    string createdAt;
    string updatedAt;
    string? lastLoginAt;
}; // Initialize MongoDB client

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

final mongodb:Client mongoDb = check new ({
    connection: connectionString
});

// Document operations
public function createDocument(string collection, map<json> data, string? documentId = ()) returns string|error {
    io:println("📝 Creating document in collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);
    if documentId is string {
        io:println("📋 Using provided document ID: ", documentId);
        // Add the document ID to the data
        data["_id"] = documentId;

        // Insert the document
        check mongoCollection->insertOne(data);

        io:println("✅ Document created successfully with ID: ", documentId);
        return "Document created with ID: " + documentId;
    } else {
        io:println("🆔 Auto-generating document ID");
        // Insert the document (MongoDB will auto-generate ID)
        check mongoCollection->insertOne(data);

        // Get the generated ID (assuming data has been modified with _id)
        string generatedId = data["_id"].toString();
        io:println("✅ Document created successfully with auto-generated ID: ", generatedId);
        return "Document created with auto-generated ID: " + generatedId;
    }
}

public function getDocument(string collection, string email = "") returns map<json>|error {
    io:println("📖 Getting document from collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);
    // Create filter to match the specific document
    map<json> filter = {"email": email};

    io:println("🔍 Querying document with email filter...");
    map<json>|error|() result = check mongoCollection->findOne(filter);

    if result is error {
        io:println("❌ Error retrieving document: ", result.message());
        return error("Error retrieving document: " + result.message());
    } else if result is () {
        io:println("❌ Document not found");
        return error("Document not found");
    } else {
        io:println("✅ Document retrieved successfully");
        return result;
    }
}

# Description.
#
# + collection - parameter description  
# + filter - parameter description
# + return - return value description
public function getDocumentWithFilters(string collection, map<json> filter = {}) returns map<json>|error {
    io:println("📖 Getting document from collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);
    io:println("🔍 Querying document with filter...");
    map<json>|error|() result = mongoCollection->findOne(filter, {});

    if result is error {
        io:println("❌ Error retrieving document: ", result.message());
        return error("Error retrieving document: " + result.message());
    } else if result is () {
        io:println("❌ Document not found");
        return error("Document not found");
    }

    io:println("✅ Document retrieved successfully");
    return result ?: {};
}

public function updateDocument(string collection, string documentId, map<json> data) returns error? {
    io:println("✏️ Updating document in collection: ", collection, " with ID: ", documentId);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    // Create filter to match the specific document ID
    map<json> filter = {"id": documentId};

    io:println("🚀 Updating document...");
    _ = check mongoCollection->updateOne(filter, {set: data});

    io:println("✅ Document updated successfully");

}

public function deleteDocument(string collection, string documentId) returns error? {
    io:println("🗑️ Attempting to delete document from collection: ", collection, " with ID: ", documentId);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    // Create filter to match the specific document ID
    map<json> filter = {"id": documentId};

    io:println("🚀 Deleting document...");
    _ = check mongoCollection->deleteOne(filter);
    io:println("✅ Document deleted successfully");
}

public function queryUsers(
        string collection,
        map<json> filter
) returns User|error {
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
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

public function queryService(map<json> filter) returns _Service|error {
    string collection = "services";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
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

    mongodb:Database db = check mongoDb->getDatabase("main");
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

// Collection operations

// public function listDocuments(string collection) returns map<json>[]|error {
//     io:println("📋 Listing all documents in collection: ", collection);
//     // Get all documents in a collection (no filters)
//     map<json>[]|error result = queryDocuments(collection);
//     if result is map<json>[] {
//         io:println("✅ Listed ", result.length().toString(), " documents");
//     }
//     return result;
// }

public function clearCollection(string collection) returns error? {
    io:println("🧹 Clearing all documents from collection: ", collection);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("🚀 Deleting all documents...");
    _ = check mongoCollection->deleteMany({});
    io:println("✅ Collection cleared successfully");
}

// Field operations
public function updateField(string collection, string documentId, string fieldName, string value) returns error? {
    io:println("🔧 Updating field '", fieldName, "' in document: ", collection, "/", documentId);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    // Create filter to match the specific document ID
    map<json> filter = {"id": documentId};

    io:println("✏️ Updating field...");
    _ = check mongoCollection->updateOne(filter, {set: {fieldName: value}});
    io:println("✅ Field update completed");
}

public function deleteField(string collection, string documentId, string fieldName) returns error? {
    io:println("🗑️ Deleting field '", fieldName, "' from document: ", collection, "/", documentId);

    mongodb:Database db = check mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    // Create filter to match the specific document ID
    map<json> filter = {"_id": documentId};
    io:println("🔧 Removing field...");
    _ = check mongoCollection->updateOne(filter, {unset: {fieldName: ""}});
    io:println("✅ Field deletion completed");
}
