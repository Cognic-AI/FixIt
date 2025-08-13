import backend.utils;

import ballerina/io;
import ballerina/time;
import ballerinax/mongodb;

public type MessageType "text"|"image"|"file"|"location"|"system";

public type Message record {
    string id;
    string senderId;
    // string senderType; // 'client' or 'vendor'
    // string receiverId;
    string content;
    MessageType 'type;
    string timestamp; // ISO8601 string format
    boolean isRead = false;
    string? imageUrl;
    string? attachmentUrl;
    string? conversationId;
};

// public type Conversation record {
//     string id;
//     string serviceId;
//     string serviceTitle;
//     string clientId;
//     string clientName;
//     string vendorId;
//     string vendorName;
//     Message? lastMessage;
//     int unreadCount = 0;
//     string createdAt; // ISO8601 string format
//     string updatedAt; // ISO8601 string format
// };

public function queryMessages(
        map<json> filter
) returns Message[]|error {
    string collection = "messages";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    // Query without type projection to get raw documents
    stream<map<json>, mongodb:Error?> rawStream = check mongoCollection->find(
        filter,
        {},  // findOptions
        {} // projection - empty map
    );

    Message[] messages = [];
    // Process the stream and manually convert to Message records
    check from map<json> doc in rawStream
        do {
            // Convert MongoDB document to Message record with proper field mapping
            Message message = {
                id: check doc["id"],
                senderId: check doc["senderId"],
                content: check doc["content"],
                'type: doc["messageType"] is () ? "text" : check doc["messageType"],
                timestamp: check doc["timestamp"],
                isRead: doc["read"] is () ? false : check doc["read"],
                imageUrl: doc["imageUrl"] is () ? () : check doc["imageUrl"],
                attachmentUrl: doc["attachmentUrl"] is () ? () : check doc["attachmentUrl"],
                conversationId: doc["conversationId"] is () ? () : check doc["conversationId"]
            };
            messages.push(message);
        };

    if messages.length() == 0 {
        io:println("❌ No documents found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", messages.length().toString(), " messages successfully");
    return messages;

}

public function queryMessagesWithOptions(
        map<json> filter,
        map<json> findOptions
) returns Message[]|error {
    string collection = "messages";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🎯 Using findOptions: ", findOptions.toString());
    io:println("🚀 Executing query...");

    // Create proper FindOptions from the map
    mongodb:FindOptions options = {};

    // Handle sort option
    if findOptions["sort"] is map<json> {
        options.sort = <map<json>>findOptions["sort"];
    }

    // Handle limit option
    if findOptions["limit"] is int {
        options.'limit = <int>findOptions["limit"];
    }

    // Handle skip option
    if findOptions["skip"] is int {
        options.skip = <int>findOptions["skip"];
    }

    // Query without type projection to get raw documents
    stream<map<json>, mongodb:Error?> rawStream = check mongoCollection->find(
        filter,
        options,  // Pass the proper FindOptions
        {} // projection - empty map
    );

    Message[] messages = [];
    // Process the stream and manually convert to Message records
    check from map<json> doc in rawStream
        do {
            // Convert MongoDB document to Message record with proper field mapping
            Message message = {
                id: check doc["id"],
                senderId: check doc["senderId"],
                content: check doc["content"],
                'type: doc["messageType"] is () ? "text" : check doc["messageType"],
                timestamp: check doc["timestamp"],
                isRead: doc["read"] is () ? false : check doc["read"],
                imageUrl: doc["imageUrl"] is () ? () : check doc["imageUrl"],
                attachmentUrl: doc["attachmentUrl"] is () ? () : check doc["attachmentUrl"],
                conversationId: doc["conversationId"] is () ? () : check doc["conversationId"]
            };
            messages.push(message);
        };

    if messages.length() == 0 {
        io:println("❌ No documents found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", messages.length().toString(), " messages successfully");
    return messages;
}

public function markAsRead(
        string conversationId,
        string receiverId
) returns boolean|error {
    string collection = "messages";
    io:println("🔍 Getting document from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("🚀 Executing query...");

    map<json> filter = {
        "conversationId": conversationId,
        "senderId": {
            "$ne": receiverId
        },
        "read": false
    };

    mongodb:Update updateData = {
        "set": {
            "read": true,
            "updatedAt": time:utcToString(time:utcNow())
        }
    };

    // Query without type projection to get raw documents
    mongodb:UpdateResult|mongodb:Error results = check mongoCollection->updateMany(
        filter,
        updateData
    );
    if results is mongodb:Error {
        io:println("Error marking messages as read", results);
        return error("Failed to mark messages as read");
    }
    if results.modifiedCount == 0 {
        io:println("❌ No messages found to mark as read");
        return false;
    }
    io:println("✅ Marked ", results.modifiedCount.toString(), " messages as read successfully");
    return true;

}
