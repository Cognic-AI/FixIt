// import backend.firestore.operations as db;

// import ballerina/http;
// import ballerina/log;
// import ballerina/time;
// import ballerina/uuid;

// public function getUserChats(http:Caller caller, http:Request req, string userId) returns error? {
//     var result = db:queryDocuments("chats", {"participants": userId});

//     if result is error {
//         log:printError("Error fetching chats", result);
//         check caller->respond({
//             "success": false,
//             "message": "Failed to fetch chats"
//         });
//         return;
//     }

//     check caller->respond({
//         "success": true,
//         "chats": result
//     });
// }

// public function getChatMessages(http:Caller caller, http:Request req, string chatId) returns error? {
//     var result = db:queryDocuments("messages", {"chatId": chatId});

//     if result is error {
//         log:printError("Error fetching messages", result);
//         check caller->respond({
//             "success": false,
//             "message": "Failed to fetch messages"
//         });
//         return;
//     }

//     check caller->respond({
//         "success": true,
//         "messages": result
//     });
// }

// public function sendMessage(http:Caller caller, http:Request req, string chatId) returns error? {
//     json|error payload = req.getJsonPayload();

//     if payload is error {
//         check caller->respond({
//             "success": false,
//             "message": "Invalid request payload"
//         });
//         return;
//     }

//     json messageData = payload;
//     string messageId = uuid:createType1AsString();

//     json newMessage = {
//         "id": messageId,
//         "chatId": chatId,
//         "senderId": messageData.senderId,
//         "senderName": messageData.senderName,
//         "content": messageData.content,
//         "timestamp": time:utcNow(),
//         "read": false,
//         "messageType": messageData?.messageType ?: "text"
//     };

//     var result = db:createDocument("messages", messageId, newMessage);

//     if result is error {
//         log:printError("Error creating message", result);
//         check caller->respond({
//             "success": false,
//             "message": "Failed to send message"
//         });
//         return;
//     }

//     // Update chat's last message
//     json chatUpdate = {
//         "lastMessage": {
//             "content": messageData.content,
//             "senderId": messageData.senderId,
//             "timestamp": time:utcNow()
//         },
//         "updatedAt": time:utcNow()
//     };

//     _ = check db:updateDocument("chats", chatId, chatUpdate);

//     check caller->respond({
//         "success": true,
//         "message": newMessage
//     });
// }

// public function createChat(http:Caller caller, http:Request req) returns error? {
//     json|error payload = req.getJsonPayload();

//     if payload is error {
//         check caller->respond({
//             "success": false,
//             "message": "Invalid request payload"
//         });
//         return;
//     }

//     json chatData = payload;
//     string chatId = uuid:createType1AsString();

//     json newChat = {
//         "id": chatId,
//         "participants": chatData.participants,
//         "serviceId": chatData?.serviceId,
//         "createdAt": time:utcNow(),
//         "updatedAt": time:utcNow()
//     };

//     var result = db:createDocument("chats", chatId, newChat);

//     if result is error {
//         log:printError("Error creating chat", result);
//         check caller->respond({
//             "success": false,
//             "message": "Failed to create chat"
//         });
//         return;
//     }

//     check caller->respond({
//         "success": true,
//         "chat": newChat
//     });
// }
