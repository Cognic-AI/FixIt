import backend.models;

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// import ballerina/regex;

// configurable string configGeminiApiKey = ?;

// final string geminiApiKey = getGeminiApiKey();
configurable string geminiApiKey = ?;

// isolated function loadEnvFile() returns map<string> {
//     map<string> envVars = {};
//     string|error envFileContent = io:fileReadString(".env");

//     if envFileContent is string {
//         string[] lines = regex:split(envFileContent, "\n");
//         foreach string line in lines {
//             string trimmedLine = line.trim();
//             if trimmedLine.length() > 0 && !trimmedLine.startsWith("#") && trimmedLine.includes("=") {
//                 string[] parts = regex:split(trimmedLine, "=");
//                 if parts.length() >= 2 {
//                     string key = parts[0].trim();
//                     string value = parts[1].trim();
//                     // Remove quotes if present
//                     if value.startsWith("\"") && value.endsWith("\"") {
//                         value = value.substring(1, value.length() - 1);
//                     }
//                     envVars[key] = value;
//                 }
//             }
//         }
//     }
//     return envVars;
// }

// isolated function getGeminiApiKey() returns string {
//     map<string> envVars = loadEnvFile();

//     if envVars.hasKey("GEMINI_API_KEY") {
//         string apiKey = envVars.get("GEMINI_API_KEY");
//         if apiKey.length() > 0 {
//             log:printDebug("Using Gemini API key from .env file");
//             return apiKey;
//         }
//     }

//     log:printDebug("Gemini API key is not set in .env file or environment variable");
//     return "";
// }

final http:Client geminiClient = check new ("https://generativelanguage.googleapis.com");

public function chatWithGemini(http:Caller caller, http:Request req) returns error? {
    // Validate API key
    if geminiApiKey.length() == 0 {
        log:printError("Gemini API key is not configured");
        check caller->respond({
            "success": false,
            "message": "AI service not configured"
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

    json requestData = payload;
    string userMessage = (check requestData.message).toString();

    // Prepare Gemini API request
    json geminiRequest = {
        "contents": [
            {
                "parts": [
                    {
                        "text": userMessage
                    }
                ]
            }
        ]
    };

    http:Request geminiReq = new;
    geminiReq.setJsonPayload(geminiRequest);
    geminiReq.setHeader("Content-Type", "application/json");

    http:Response|error response = geminiClient->post("/v1beta/models/gemini-2.0-flash-lite:generateContent?key=" + geminiApiKey, geminiReq);

    if response is error {
        log:printError("Error calling Gemini API", response);
        check caller->respond({
            "success": false,
            "message": "AI service unavailable"
        });
        return;
    }

    json geminiResponse = check response.getJsonPayload(); // Extract the response text from Gemini

    // First, let's log the entire response to understand its structure
    io:println("Full Gemini API response: ", geminiResponse);

    string responseText = "";
    if geminiResponse is map<json> {
        // Check if the response contains an error
        if geminiResponse.hasKey("error") {
            json errorInfo = geminiResponse.get("error");
            log:printError("Gemini API error: " + errorInfo.toString());
            check caller->respond({
                "success": false,
                "message": "AI service error: " + errorInfo.toString()
            });
            return;
        }

        // Check if candidates key exists
        if geminiResponse.hasKey("candidates") {
            io:println("Gemini response candidates: ", geminiResponse.candidates);
            json[] candidates = check (geminiResponse.candidates).ensureType();
            if candidates.length() > 0 {
                io:println("Gemini response candidate contents: ", candidates[0].content);
                json contents = check (candidates[0].content).ensureType();
                io:println("Gemini response parts: ", contents.parts);
                json[] parts = check (contents.parts).ensureType();
                if parts.length() > 0 {
                    io:println("Gemini response part text: ", parts[0].text);
                    responseText = check (parts[0].text).ensureType(string);
                }
            }
        } else {
            log:printError("No candidates found in Gemini response");
            check caller->respond({
                "success": false,
                "message": "Invalid response from AI service"
            });
            return;
        }
    }

    string conversationId = (check requestData.conversationId).toString();
    string senderId = conversationId; // Assuming senderId is same as conversationId
    // Extract fields safely from JSON
    string messageId = uuid:createType1AsString();
    string messageType = "text"; // Default to text, can be extended for other types

    json newMessage = {
        "id": messageId,
        "senderId": senderId,
        "content": userMessage,
        "timestamp": time:utcToString(time:utcNow()),
        "read": false,
        "messageType": messageType,
        "conversationId": conversationId // Assuming conversationId is same as chatId
    };

    string aiMessageId = uuid:createType1AsString();

    json aiMessage = {
        "id": aiMessageId,
        "senderId": "ai",
        "content": responseText,
        "timestamp": time:utcToString(time:utcNow()),
        "read": false,
        "messageType": messageType,
        "conversationId": conversationId // Assuming conversationId is same as chatId
    };

    var result = models:createDocument("messages", <map<json>>newMessage, messageId);
    var result2 = models:createDocument("messages", <map<json>>aiMessage, aiMessageId);
    if result is error {
        log:printError("Error creating message", result);
        check caller->respond({
            "success": false,
            "message": "Failed to send message"
        });
        return;
    }
    if result2 is error {
        log:printError("Error creating AI message", result2);
        check caller->respond({
            "success": false,
            "message": "Failed to send AI message"
        });
        return;
    }

    check caller->respond({
        "success": true,
        "response": responseText,
        "message": "AI response generated successfully"
    });
}

public function getLLMResponse(http:Caller caller, http:Request req) returns error? {
    // Validate API key
    if geminiApiKey.length() == 0 {
        log:printError("Gemini API key is not configured");
        check caller->respond({
            "success": false,
            "message": "AI service not configured"
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

    json requestData = payload;

    // Generate recommendation prompt based on user preferences
    string prompt = "Based on the following question, answer as a vendor: " + requestData.toString();

    // Call Gemini for recommendations
    json geminiRequest = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt
                    }
                ]
            }
        ]
    };

    http:Request geminiReq = new;
    geminiReq.setJsonPayload(geminiRequest);
    geminiReq.setHeader("Content-Type", "application/json");

    http:Response|error response = geminiClient->post("/v1beta/models/gemini-2.0-flash-lite:generateContent?key=" + geminiApiKey
    , geminiReq);

    if response is error {
        log:printError("Error getting recommendations", response);
        check caller->respond({
            "success": false,
            "message": "Recommendation service unavailable"
        });
        return;
    }

    json geminiResponse = check response.getJsonPayload();

    // Log the response to understand its structure
    io:println("Full Gemini API response in getLLMResponse: ", geminiResponse);

    // Handle the response similar to chatWithGemini
    if geminiResponse is map<json> {
        // Check if the response contains an error
        if geminiResponse.hasKey("error") {
            json errorInfo = geminiResponse.get("error");
            log:printError("Gemini API error in getLLMResponse: " + errorInfo.toString());
            check caller->respond({
                "success": false,
                "message": "AI service error: " + errorInfo.toString()
            });
            return;
        }

        // Check if candidates key exists and extract the response
        if geminiResponse.hasKey("candidates") {
            json[] candidates = check (geminiResponse.candidates).ensureType();
            if candidates.length() > 0 {
                json contents = check (candidates[0].content).ensureType();
                json[] parts = check (contents.parts).ensureType();
                if parts.length() > 0 {
                    string responseText = check (parts[0].text).ensureType(string);
                    check caller->respond({
                        "success": true,
                        "recommendations": responseText
                    });
                    return;
                }
            }
        }
    }

    check caller->respond({
        "success": false,
        "message": "Invalid response from AI service"
    });
}
