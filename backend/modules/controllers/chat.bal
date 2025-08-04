import backend.models;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

public function getChatMessages(http:Caller caller, http:Request req) returns error? {
    models:User|error user = check authenticateRequest(req);
    if user is error {
        check caller->respond({
            "success": false,
            "message": "Authentication failed"
        });
        return;
    }
    json|error payload = req.getJsonPayload();

    if payload is error {
        check caller->respond({
            "success": false,
            "message": "Invalid request payload"
        });
        return;
    }

    json messageData = payload;

    // Extract conversationId safely from JSON
    string conversationId = check messageData.conversationId;

    map<json> filter = {
        "conversationId": conversationId
    };
    var result = models:queryMessages(filter);

    if result is error {
        log:printError("Error fetching messages", result);
        check caller->respond({
            "success": false,
            "message": "Failed to fetch messages"
        });
        return;
    }

    _ = check models:markAsRead(conversationId, user.id);

    check caller->respond({
        "success": true,
        "messages": result
    });
}

public function getConversationLast(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();

    if payload is error {
        check caller->respond({
            "success": false,
            "message": "Invalid request payload"
        });
        return;
    }

    json messageData = payload;

    // Extract conversationId safely from JSON
    json conversationId = check messageData.conversationId;

    map<json> filter = {
        "conversationId": conversationId
    };

    map<json> findOptions = {
        "sort": {"timestamp": -1},
        "limit": 1
    };

    var result = models:queryMessagesWithOptions(filter, findOptions);

    if result is error {
        log:printError("Error fetching messages", result);
        check caller->respond({
            "success": false,
            "message": "Failed to fetch messages"
        });
        return;
    }

    io:println("Last message for conversation ", conversationId, ": ", result);

    check caller->respond({
        "success": true,
        "messages": result
    });
}

public function sendMessage(http:Caller caller, http:Request req) returns error? {
    json|error payload = req.getJsonPayload();

    if payload is error {
        check caller->respond({
            "success": false,
            "message": "Invalid request payload"
        });
        return;
    }

    json messageData = payload;
    string messageId = uuid:createType1AsString();

    // Extract fields safely from JSON
    json senderId = check messageData.senderId;
    json conversationId = check messageData.conversationId;
    json content = check messageData.content;
    json messageType = messageData.messageType is () ? "text" : check messageData.messageType;

    json newMessage = {
        "id": messageId,
        "senderId": senderId,
        "content": content,
        "timestamp": time:utcToString(time:utcAddSeconds(time:utcNow(), 19800)),
        "read": false,
        "messageType": messageType,
        "conversationId": conversationId // Assuming conversationId is same as chatId
    };

    var result = models:createDocument("messages", <map<json>>newMessage, messageId);

    if result is error {
        log:printError("Error creating message", result);
        check caller->respond({
            "success": false,
            "message": "Failed to send message"
        });
        return;
    }

    // Update chat's last message
    // json chatContent = check messageData.content;
    // json chatSenderId = check messageData.senderId;

    // json chatUpdate = {
    //     "lastMessage": {
    //         "content": chatContent,
    //         "senderId": chatSenderId,
    //         "timestamp": time:utcToString(time:utcNow())
    //     },
    //     "updatedAt": time:utcToString(time:utcNow())
    // };

    // _ = check models:updateDocument("requests", conversationId, <map<json>>chatUpdate);

    check caller->respond({
        "success": true,
        "message": newMessage
    });
}

public function getUnreadMessageCount(http:Caller caller, http:Request req) returns error? {
    // url-/unread-count?userId=$userId'

    json|error queryParams = req.getQueryParams();
    if queryParams is error {
        check caller->respond({
            "success": false,
            "message": "Invalid query parameters"
        });
        return;
    }

    json userId = check queryParams.userId;
    map<json> filter = {
        "$or": [
            {"senderId": userId},
            {"receiverId": userId}
        ],
        "read": false
    };

    var result = models:queryMessages(filter);

    if result is error {
        log:printError("Error fetching unread messages", result);
        check caller->respond({
            "success": false,
            "message": "Failed to fetch unread messages"
        });
        return;
    }

    int unreadCount = result.length();

    check caller->respond({
        "success": true,
        "unreadCount": unreadCount
    });
}
