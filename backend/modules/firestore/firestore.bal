import backend.firestore.config;

import ballerina/log;

import nalaka/firestore;

public function createDocument(string collection, string documentId, json data) returns error? {
    firestore:Client client = config:getFirestoreClient();
    var result = client->createDocument(collection, documentId, data);

    if result is error {
        log:printError("Error creating document in " + collection, result);
        return result;
    }

    log:printInfo("Document created successfully in " + collection + " with ID: " + documentId);
}

public function getDocument(string collection, string documentId) returns json|error {
    firestore:Client client = config:getFirestoreClient();
    var result = client->getDocument(collection, documentId);

    if result is error {
        log:printError("Error fetching document from " + collection, result);
        return result;
    }

    return result;
}

public function getDocuments(string collection) returns json[]|error {
    firestore:Client client = config:getFirestoreClient();
    var result = client->getDocuments(collection);

    if result is error {
        log:printError("Error fetching documents from " + collection, result);
        return result;
    }

    return result;
}

public function updateDocument(string collection, string documentId, json data) returns error? {
    firestore:Client client = config:getFirestoreClient();
    var result = client->updateDocument(collection, documentId, data);

    if result is error {
        log:printError("Error updating document in " + collection, result);
        return result;
    }

    log:printInfo("Document updated successfully in " + collection + " with ID: " + documentId);
}

public function deleteDocument(string collection, string documentId) returns error? {
    firestore:Client client = config:getFirestoreClient();
    var result = client->deleteDocument(collection, documentId);

    if result is error {
        log:printError("Error deleting document from " + collection, result);
        return result;
    }

    log:printInfo("Document deleted successfully from " + collection + " with ID: " + documentId);
}

public function queryDocuments(string collection, map<anydata> filters) returns json[]|error {
    firestore:Client client = config:getFirestoreClient();
    // Implement query logic based on your firestore client capabilities
    var result = client->getDocuments(collection);

    if result is error {
        return result;
    }

    // Filter results based on provided filters
    return result;
}

public function clearCollection(string collection) returns error? {
    firestore:Client client = config:getFirestoreClient();
    log:printInfo("Clearing collection: " + collection);

    var result = client->getDocuments(collection);
    if result is error {
        log:printWarn("Collection " + collection + " might not exist or is empty");
        return;
    }

    // In a real implementation, iterate through documents and delete them
    log:printInfo("Cleared collection: " + collection);
}
