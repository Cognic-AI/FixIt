import ballerina/http;
import ballerina/log;

configurable string geminiApiKey = ?;

http:Client geminiClient = check new ("https://generativelanguage.googleapis.com");

public function chatWithGemini(http:Caller caller, http:Request req) returns error? {
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

    http:Response|error response = geminiClient->post("/v1beta/models/gemini-pro:generateContent?key=" + geminiApiKey, geminiReq);

    if response is error {
        log:printError("Error calling Gemini API", response);
        check caller->respond({
            "success": false,
            "message": "AI service unavailable"
        });
        return;
    }

    json geminiResponse = check response.getJsonPayload();

    check caller->respond({
        "success": true,
        "response": geminiResponse,
        "message": "AI response generated successfully"
    });
}

public function getRecommendations(http:Caller caller, http:Request req) returns error? {
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
    string prompt = "Based on the following user preferences, recommend services: " + requestData.toString();

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

    http:Response|error response = geminiClient->post("/v1beta/models/gemini-pro:generateContent?key=" + geminiApiKey, geminiReq);

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
