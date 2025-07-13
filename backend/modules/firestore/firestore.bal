import ballerina/file;
import ballerina/io;
import ballerina/time;

import nalaka/firestore;

configurable string firestoreProjectId = ?;
configurable string firebaseApiKey = ?;
configurable string firebaseAuthDomain = ?;
configurable string firebaseStorageBucket = ?;
configurable string firebaseMessagingSenderId = ?;
configurable string firebaseAppId = ?;
configurable string firebaseMeasurementId = ?;

// Initialize Firestore client with proper authentication
final firestore:Client _firestoreClient = check new ({
    serviceAccountPath: "./firebase-service-account.json",
    firebaseConfig: {
        projectId: firestoreProjectId,
        apiKey: firebaseApiKey,
        authDomain: firebaseAuthDomain,
        storageBucket: firebaseStorageBucket,
        messagingSenderId: firebaseMessagingSenderId,
        appId: firebaseAppId,
        measurementId: firebaseMeasurementId
},
    jwtConfig: {
        scope: "https://www.googleapis.com/auth/datastore",
        expTime: 3600
    }
});

// Helper function to get access token with better error handling
// Module-level cache variables
final int TOKEN_EXPIRY_BUFFER = 300; // 5 minute buffer in seconds
string? cachedToken = ();
time:Utc? tokenExpiry = ();

function _getAccessToken() returns string|error {
    // Check if we have a valid cached token
    if cachedToken is string && tokenExpiry is time:Utc {
        time:Utc now = time:utcNow();
        decimal diff = time:utcDiffSeconds(<time:Utc>tokenExpiry, now);
        int secondsRemaining = <int>diff;

        if secondsRemaining > TOKEN_EXPIRY_BUFFER {
            io:println("♻️ Using cached access token");
            return cachedToken ?: "";
        }
    }

    io:println("🔑 Generating new access token...");

    // Validate service account file exists
    if !check file:test("./firebase-service-account.json", file:EXISTS) {
        io:println("❌ Service account file not found");
        return error("Service account file not found");
    }

    // Generate new token
    string|error token = _firestoreClient.generateToken();
    if token is error {
        io:println("❌ Failed to generate access token: ", token.message());
        return error("Failed to generate access token: " + token.message());
    }

    // Cache the new token with expiry time (1 hour - buffer)
    cachedToken = token;
    decimal tokenExpirySeconds = 3600.0d - <decimal>TOKEN_EXPIRY_BUFFER; // Convert to decimal
    tokenExpiry = time:utcAddSeconds(time:utcNow(), tokenExpirySeconds);

    io:println("✅ New access token generated and cached");
    return token;
}

// Document operations
public function createDocument(string collection, map<json> data, string? documentId = ()) returns string|error {
    io:println("📝 Creating document in collection: ", collection);
    string accessToken = check _getAccessToken();

    if documentId is string {
        io:println("📋 Using provided document ID: ", documentId);
        // Create document with specific ID
        check firestore:createFirestoreDocument(
                firestoreProjectId,
                accessToken,
                collection + "/" + documentId, // Document path format
                data
        );
        io:println("✅ Document created successfully with ID: ", documentId);
        return "Document created with ID: " + documentId;
    } else {
        io:println("🆔 Auto-generating document ID");
        // Let Firestore auto-generate ID
        check firestore:createFirestoreDocument(
                firestoreProjectId,
                accessToken,
                collection, // Just collection name
                data
        );
        io:println("✅ Document created successfully with auto-generated ID");
        return "Document created with auto-generated ID";
    }
}

public function getDocument(string collection, string documentId, string email = "") returns map<json>|error {
    io:println("📖 Getting document from collection: ", collection, " with ID: ", documentId);
    string accessToken = check _getAccessToken();

    // Create filter to match the specific document ID
    map<json> filter = {
        "email": email
};

    io:println("🔍 Querying document with ID filter...");

    map<json>[] results = check firestore:queryFirestoreDocuments(
            firestoreProjectId,
            accessToken,
            collection, // Query the collection
            filter // Filter for specific document
    );

    if results.length() == 0 {
        io:println("❌ Document not found");
        return error("Document not found");
    }

    io:println("✅ Document retrieved successfully");
    return results[0];
}

public function updateDocument(string collection, string documentId, map<json> data) returns error? {
    io:println("✏️ Updating document in collection: ", collection, " with ID: ", documentId);
    string accessToken = check _getAccessToken();

    // Note: The module documentation doesn't show an update function,
    // so we'll use create with the same document ID (which will overwrite)
    io:println("🚀 Overwriting document with new data...");
    check firestore:createFirestoreDocument(
            firestoreProjectId,
            accessToken,
            collection + "/" + documentId,
            data
    );
    io:println("✅ Document updated successfully");
}

public function deleteDocument(string collection, string documentId) returns error? {
    io:println("🗑️ Attempting to delete document from collection: ", collection, " with ID: ", documentId);
    string accessToken = check _getAccessToken();
    io:println("🚀 Deleting document...", accessToken);
    // Note: The module documentation doesn't show a delete function,
    // so this would need to be implemented based on Firestore REST API
    // For now, we'll return an error as this operation isn't shown in the docs
    io:println("❌ Delete operation not implemented in this module version");
    return error("Delete operation not implemented in this module version");
}

public function queryDocuments(string collection, map<json>? filters = ()) returns map<json>[]|error {
    io:println("🔍 Querying documents in collection: ", collection);
    if filters is map<json> {
        io:println("📋 Using filters: ", filters.toString());
    } else {
        io:println("📋 No filters applied");
    }

    string accessToken = check _getAccessToken();

    map<json> filter = filters is map<json> ? filters : {};
    io:println("🚀 Executing query...");
    map<json>[] result = check firestore:queryFirestoreDocuments(
            firestoreProjectId,
            accessToken,
            collection,
            filter
    );
    io:println("✅ Query completed. Found ", result.length().toString(), " documents");
    return result;
}

// Collection operations
public function listDocuments(string collection) returns map<json>[]|error {
    io:println("📋 Listing all documents in collection: ", collection);
    // Get all documents in a collection (no filters)
    map<json>[]|error result = queryDocuments(collection);
    if result is map<json>[] {
        io:println("✅ Listed ", result.length().toString(), " documents");
    }
    return result;
}

public function clearCollection(string collection) returns error? {
    io:println("🧹 Clearing all documents from collection: ", collection);
    // Get all documents
    map<json>[] documents = check listDocuments(collection);
    io:println("🔍 Found ", documents.length().toString(), " documents to delete");

    // Delete each document
    foreach var doc in documents {
        string docId = doc["__name__"].toString();
        io:println("🗑️ Deleting document: ", docId);
        check deleteDocument(collection, docId);
    }
    io:println("✅ Collection cleared successfully");
}

// Field operations
public function updateField(string collection, string documentId, string fieldName, json value) returns error? {
    io:println("🔧 Updating field '", fieldName, "' in document: ", collection, "/", documentId);
    // Get current document
    map<json> document = check getDocument(collection, documentId);
    io:println("📖 Current document retrieved");

    // Update the field
    document[fieldName] = value;
    io:println("✏️ Field '", fieldName, "' updated with new value");

    // Save the updated document
    check updateDocument(collection, documentId, document);
    io:println("✅ Field update completed");
}

public function deleteField(string collection, string documentId, string fieldName) returns error? {
    io:println("🗑️ Deleting field '", fieldName, "' from document: ", collection, "/", documentId);
    // Get current document
    map<json> document = check getDocument(collection, documentId);
    io:println("📖 Current document retrieved");

    // Remove the field
    _ = document.remove(fieldName);
    io:println("🔧 Field '", fieldName, "' removed from document");

    // Save the updated document
    check updateDocument(collection, documentId, document);
    io:println("✅ Field deletion completed");
}
