import backend.utils;

import ballerina/io;
import ballerinax/mongodb;

public type serviceSubscriptionResponse record {
    string id;
    string serviceId;
    string clientId;
};

public function querySubscriptions(
        map<json> filter
) returns serviceSubscriptionResponse[]|error {
    string collection = "subscriptions";
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

    serviceSubscriptionResponse[] subscriptions = [];
    // Process the stream and manually convert to Message records
    check from map<json> doc in rawStream
        do {
            // Convert MongoDB document to Message record with proper field mapping
            serviceSubscriptionResponse subscription = {
                id: check doc["id"],
                serviceId: check doc["serviceId"],
                clientId: check doc["clientId"]
            };
            subscriptions.push(subscription);
        };

    if subscriptions.length() == 0 {
        io:println("❌ No documents found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", subscriptions.length().toString(), " subscriptions successfully");
    return subscriptions;

}

// public function queryMessagesWithOptions(
//         map<json> filter,
//         map<json> findOptions
// ) returns Message[]|error {
//     string collection = "messages";
//     io:println("🔍 Getting document from collection: ", collection);

//     mongodb:Database db = check utils:mongoDb->getDatabase("main");
//     mongodb:Collection mongoCollection = check db->getCollection(collection);

//     io:println("📋 Using filter: ", filter.toString());
//     io:println("🎯 Using findOptions: ", findOptions.toString());
//     io:println("🚀 Executing query...");

//     // Create proper FindOptions from the map
//     mongodb:FindOptions options = {};

//     // Handle sort option
//     if findOptions["sort"] is map<json> {
//         options.sort = <map<json>>findOptions["sort"];
//     }

//     // Handle limit option
//     if findOptions["limit"] is int {
//         options.'limit = <int>findOptions["limit"];
//     }

//     // Handle skip option
//     if findOptions["skip"] is int {
//         options.skip = <int>findOptions["skip"];
//     }

//     // Query without type projection to get raw documents
//     stream<map<json>, mongodb:Error?> rawStream = check mongoCollection->find(
//         filter,
//         options,  // Pass the proper FindOptions
//         {} // projection - empty map
//     );

//     Message[] messages = [];
//     // Process the stream and manually convert to Message records
//     check from map<json> doc in rawStream
//         do {
//             // Convert MongoDB document to Message record with proper field mapping
//             Message message = {
//                 id: check doc["id"],
//                 senderId: check doc["senderId"],
//                 content: check doc["content"],
//                 'type: doc["messageType"] is () ? "text" : check doc["messageType"],
//                 timestamp: check doc["timestamp"],
//                 isRead: doc["read"] is () ? false : check doc["read"],
//                 imageUrl: doc["imageUrl"] is () ? () : check doc["imageUrl"],
//                 attachmentUrl: doc["attachmentUrl"] is () ? () : check doc["attachmentUrl"],
//                 conversationId: doc["conversationId"] is () ? () : check doc["conversationId"]
//             };
//             messages.push(message);
//         };

//     if messages.length() == 0 {
//         io:println("❌ No documents found matching the filter");
//         return [];
//     }

//     io:println("✅ Retrieved ", messages.length().toString(), " messages successfully");
//     return messages;
// }
