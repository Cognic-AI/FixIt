import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/regex;

// configurable string configGeminiApiKey = ?;

final string geminiApiKey = getGeminiApiKey();

isolated function loadEnvFile() returns map<string> {
    map<string> envVars = {};
    string|error envFileContent = io:fileReadString(".env");

    if envFileContent is string {
        string[] lines = regex:split(envFileContent, "\n");
        foreach string line in lines {
            string trimmedLine = line.trim();
            if trimmedLine.length() > 0 && !trimmedLine.startsWith("#") && trimmedLine.includes("=") {
                string[] parts = regex:split(trimmedLine, "=");
                if parts.length() >= 2 {
                    string key = parts[0].trim();
                    string value = parts[1].trim();
                    // Remove quotes if present
                    if value.startsWith("\"") && value.endsWith("\"") {
                        value = value.substring(1, value.length() - 1);
                    }
                    envVars[key] = value;
                }
            }
        }
    }
    return envVars;
}

isolated function getGeminiApiKey() returns string {
    map<string> envVars = loadEnvFile();

    if envVars.hasKey("GEMINI_API_KEY") {
        string apiKey = envVars.get("GEMINI_API_KEY");
        if apiKey.length() > 0 {
            log:printDebug("Using Gemini API key from .env file");
            return apiKey;
        }
    }

    log:printDebug("Gemini API key is not set in .env file or environment variable");
    return "";
}

final http:Client geminiClient = check new ("https://generativelanguage.googleapis.com");

public isolated function chatWithGemini(http:Caller caller, http:Request req) returns error? {
    string _ = getGeminiApiKey();
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

    string responseText = "";
    if geminiResponse is map<json> {
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
    }

    check caller->respond({
"success": true,
"response": responseText,
"message": "AI response generated successfully"
});
}

public function getLLMResponse(http:Caller caller, http:Request req) returns error? {
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

    http:Response|error response = geminiClient->post("/v1beta/models/gemini-2.0-flash-lite:generateContent?key=" + getGeminiApiKey()
    , geminiReq);

    if response is error {
        log:printError("Error getting recommendations", response);
        check caller->respond({
            "success": false,
            "message": "Recommendation service unavailable"
        });
        return;
    }

    json recommendations = check response.getJsonPayload();

    check caller->respond({
        "success": true,
        "recommendations": recommendations
    });
}
