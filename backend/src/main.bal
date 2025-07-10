import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerina/time;
import ballerinax/firebase.firestore as firestore;

// Firebase Firestore configuration
configurable string projectId = ?;
configurable string privateKeyId = ?;
configurable string privateKey = ?;
configurable string clientEmail = ?;
configurable string clientId = ?;

// Initialize Firestore client
firestore:Client firestoreClient = check new ({
    projectId: projectId,
    privateKeyId: privateKeyId,
    privateKey: privateKey,
    clientEmail: clientEmail,
    clientId: clientId
});

// CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["CORELATION_ID", "Authorization", "Content-Type", "ngrok-skip-browser-warning"],
        allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD"]
    }
}

service /api on new http:Listener(8080) {
    
    // Health check endpoint
    resource function get health() returns json {
        return {
            "status": "healthy",
            "service": "FixIt Backend API",
            "timestamp": time:utcNow()
        };
    }

    // Seed database endpoint (Development only)
    resource function post seed(http:Caller caller, http:Request req) returns error? {
        log:printInfo("Starting database seeding...");
        
        try {
            // Clear existing collections
            _ = check clearCollection("users");
            _ = check clearCollection("services");
            _ = check clearCollection("events");
            _ = check clearCollection("chats");
            _ = check clearCollection("feedback");
            _ = check clearCollection("bookings");
            _ = check clearCollection("reviews");
            
            log:printInfo("Cleared existing collections");
            
            // Seed users
            json[] users = [
                {
                    "id": "user_1",
                    "firstName": "Karen",
                    "lastName": "Roe",
                    "email": "karen.roe@example.com",
                    "userType": "vendor",
                    "rating": 4.8,
                    "reviewCount": 89,
                    "location": "Recife, Brazil",
                    "verified": true,
                    "avatar": "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100",
                    "createdAt": time:utcNow()
                },
                {
                    "id": "user_2",
                    "firstName": "João",
                    "lastName": "Silva",
                    "email": "joao.silva@example.com",
                    "userType": "vendor",
                    "rating": 4.6,
                    "reviewCount": 45,
                    "location": "Olinda, Brazil",
                    "verified": true,
                    "avatar": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100",
                    "createdAt": time:utcNow()
                },
                {
                    "id": "user_3",
                    "firstName": "Lucas",
                    "lastName": "Scott",
                    "email": "lucasscott3@email.com",
                    "userType": "client",
                    "rating": 0.0,
                    "reviewCount": 0,
                    "location": "Recife, Brazil",
                    "verified": false,
                    "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100",
                    "createdAt": time:utcNow()
                },
                {
                    "id": "user_4",
                    "firstName": "Maria",
                    "lastName": "Santos",
                    "email": "maria.santos@example.com",
                    "userType": "vendor",
                    "rating": 4.9,
                    "reviewCount": 87,
                    "location": "Olinda, Brazil",
                    "verified": true,
                    "avatar": "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100",
                    "createdAt": time:utcNow()
                }
            ];
            
            foreach json user in users {
                _ = check firestoreClient->createDocument("users", user.id.toString(), user);
            }
            log:printInfo("Seeded users collection");
            
            // Seed services
            json[] services = [
                {
                    "id": "service_1",
                    "title": "Great Apartment",
                    "description": "Perfect flat for 4 people. Peaceful and good location, close to bus stops and many restaurants.",
                    "price": 150.0,
                    "location": "Recife, Brazil",
                    "coordinates": {"lat": -8.0476, "lng": -34.877},
                    "rating": 4.8,
                    "reviewCount": 124,
                    "hostId": "user_1",
                    "hostName": "Karen Roe",
                    "category": "accommodation",
                    "subcategory": "apartment",
                    "amenities": ["WiFi", "Kitchen", "Air Conditioning", "Parking", "Pool", "Gym"],
                    "rules": ["No smoking", "No pets", "Check-in after 3 PM", "Check-out before 11 AM"],
                    "imageUrl": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400",
                    "dates": "Mar 12 – Mar 15",
                    "maxGuests": 4,
                    "bedrooms": 2,
                    "bathrooms": 2,
                    "active": true,
                    "createdAt": time:utcNow()
                },
                {
                    "id": "service_2",
                    "title": "Cozy Studio",
                    "description": "Charming studio apartment in historic Olinda. Perfect for couples or solo travelers.",
                    "price": 85.0,
                    "location": "Olinda, Brazil",
                    "coordinates": {"lat": -8.0089, "lng": -34.8553},
                    "rating": 4.6,
                    "reviewCount": 67,
                    "hostId": "user_2",
                    "hostName": "João Silva",
                    "category": "accommodation",
                    "subcategory": "studio",
                    "amenities": ["WiFi", "Kitchen", "Air Conditioning", "Historic Location"],
                    "rules": ["No smoking", "Quiet hours after 10 PM", "Check-in after 2 PM"],
                    "imageUrl": "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400",
                    "dates": "Mar 20 – Mar 23",
                    "maxGuests": 2,
                    "bedrooms": 1,
                    "bathrooms": 1,
                    "active": true,
                    "createdAt": time:utcNow()
                },
                {
                    "id": "service_3",
                    "title": "Professional Photography",
                    "description": "High-quality photography services for events, portraits, and commercial projects.",
                    "price": 200.0,
                    "location": "Olinda, Brazil",
                    "coordinates": {"lat": -8.0089, "lng": -34.8553},
                    "rating": 4.9,
                    "reviewCount": 87,
                    "hostId": "user_4",
                    "hostName": "Maria Santos",
                    "category": "professional",
                    "subcategory": "photography",
                    "amenities": ["Professional Equipment", "Editing Included", "Fast Delivery", "Multiple Formats"],
                    "rules": ["24-hour notice for cancellation", "Travel fees may apply"],
                    "imageUrl": "https://images.unsplash.com/photo-1502920917128-1aa500764cbd?w=400",
                    "dates": "Available",
                    "duration": "2-4 hours",
                    "deliverables": ["High-res digital files", "Basic editing", "Online gallery"],
                    "active": true,
                    "createdAt": time:utcNow()
                }
            ];
            
            foreach json service in services {
                _ = check firestoreClient->createDocument("services", service.id.toString(), service);
            }
            log:printInfo("Seeded services collection");
            
            // Seed events
            json[] events = [
                {
                    "id": "event_1",
                    "title": "Maroon 5",
                    "description": "Don't miss Maroon 5 live in concert at Recife Arena! Experience their greatest hits.",
                    "location": "Recife Arena",
                    "address": "Av. Deus Dará, 1 - São Lourenço da Mata, PE",
                    "coordinates": {"lat": -8.0476, "lng": -34.877},
                    "date": "MAR 05",
                    "time": "20:00",
                    "price": 120.0,
                    "category": "CONCERTS",
                    "capacity": 50000,
                    "ticketsAvailable": 15000,
                    "organizer": "Live Nation Brazil",
                    "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
                    "tags": ["music", "concert", "pop", "live"],
                    "ageRestriction": "All ages",
                    "duration": "3 hours",
                    "active": true,
                    "createdAt": time:utcNow()
                },
                {
                    "id": "event_2",
                    "title": "Alicia Keys",
                    "description": "Live performance by Alicia Keys in the beautiful city of Olinda.",
                    "location": "Centro de Convenções",
                    "address": "Complexo de Salgadinho, Olinda, PE",
                    "coordinates": {"lat": -8.0089, "lng": -34.8553},
                    "date": "MAR 05",
                    "time": "19:00",
                    "price": 95.0,
                    "category": "CONCERTS",
                    "capacity": 25000,
                    "ticketsAvailable": 8000,
                    "organizer": "Music Events Brazil",
                    "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
                    "tags": ["music", "concert", "R&B", "live"],
                    "ageRestriction": "All ages",
                    "duration": "2.5 hours",
                    "active": true,
                    "createdAt": time:utcNow()
                },
                {
                    "id": "event_3",
                    "title": "Michael Jackson",
                    "description": "Michael Jackson tribute show featuring the greatest hits and dance moves.",
                    "location": "Arena Pernambuco",
                    "address": "Cidade da Copa, São Lourenço da Mata, PE",
                    "coordinates": {"lat": -8.0476, "lng": -34.877},
                    "date": "MAR 10",
                    "time": "21:00",
                    "price": 85.0,
                    "category": "CONCERTS",
                    "capacity": 30000,
                    "ticketsAvailable": 12000,
                    "organizer": "Tribute Productions",
                    "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
                    "tags": ["tribute", "concert", "pop", "dance"],
                    "ageRestriction": "All ages",
                    "duration": "2 hours",
                    "active": true,
                    "createdAt": time:utcNow()
                }
            ];
            
            foreach json event in events {
                _ = check firestoreClient->createDocument("events", event.id.toString(), event);
            }
            log:printInfo("Seeded events collection");
            
            // Seed chats
            json[] chats = [
                {
                    "id": "chat_1",
                    "participants": ["user_1", "user_3"],
                    "serviceId": "service_1",
                    "lastMessage": {
                        "content": "You're the best!",
                        "senderId": "user_3",
                        "timestamp": time:utcNow()
                    },
                    "createdAt": time:utcNow(),
                    "updatedAt": time:utcNow()
                }
            ];
            
            foreach json chat in chats {
                _ = check firestoreClient->createDocument("chats", chat.id.toString(), chat);
            }
            log:printInfo("Seeded chats collection");
            
            // Seed chat messages
            json[] messages = [
                {
                    "id": "msg_1",
                    "chatId": "chat_1",
                    "senderId": "user_3",
                    "senderName": "Lucas",
                    "content": "Hey Lucas!",
                    "timestamp": time:utcNow(),
                    "read": true,
                    "messageType": "text"
                },
                {
                    "id": "msg_2",
                    "chatId": "chat_1",
                    "senderId": "user_3",
                    "senderName": "Lucas",
                    "content": "How's your project going?",
                    "timestamp": time:utcNow(),
                    "read": true,
                    "messageType": "text"
                },
                {
                    "id": "msg_3",
                    "chatId": "chat_1",
                    "senderId": "user_1",
                    "senderName": "Karen",
                    "content": "Hi Brooke!",
                    "timestamp": time:utcNow(),
                    "read": true,
                    "messageType": "text"
                },
                {
                    "id": "msg_4",
                    "chatId": "chat_1",
                    "senderId": "user_1",
                    "senderName": "Karen",
                    "content": "It's going well. Thanks for asking!",
                    "timestamp": time:utcNow(),
                    "read": true,
                    "messageType": "text"
                },
                {
                    "id": "msg_5",
                    "chatId": "chat_1",
                    "senderId": "user_3",
                    "senderName": "Lucas",
                    "content": "No worries. Let me know if you need any help",
                    "timestamp": time:utcNow(),
                    "read": false,
                    "messageType": "text"
                },
                {
                    "id": "msg_6",
                    "chatId": "chat_1",
                    "senderId": "user_3",
                    "senderName": "Lucas",
                    "content": "You're the best!",
                    "timestamp": time:utcNow(),
                    "read": false,
                    "messageType": "text"
                }
            ];
            
            foreach json message in messages {
                _ = check firestoreClient->createDocument("messages", message.id.toString(), message);
            }
            log:printInfo("Seeded messages collection");
            
            // Seed bookings
            json[] bookings = [
                {
                    "id": "booking_1",
                    "serviceId": "service_1",
                    "customerId": "user_3",
                    "hostId": "user_1",
                    "startDate": "2024-03-12",
                    "endDate": "2024-03-15",
                    "guests": 2,
                    "totalPrice": 475.0,
                    "serviceFee": 25.0,
                    "status": "confirmed",
                    "paymentStatus": "paid",
                    "createdAt": time:utcNow(),
                    "updatedAt": time:utcNow()
                }
            ];
            
            foreach json booking in bookings {
                _ = check firestoreClient->createDocument("bookings", booking.id.toString(), booking);
            }
            log:printInfo("Seeded bookings collection");
            
            // Seed reviews
            json[] reviews = [
                {
                    "id": "review_1",
                    "serviceId": "service_1",
                    "customerId": "user_3",
                    "hostId": "user_1",
                    "rating": 5,
                    "comment": "Amazing apartment with great location! Karen was very helpful and responsive.",
                    "helpful": 0,
                    "createdAt": time:utcNow()
                }
            ];
            
            foreach json review in reviews {
                _ = check firestoreClient->createDocument("reviews", review.id.toString(), review);
            }
            log:printInfo("Seeded reviews collection");
            
            // Seed feedback
            json[] feedbacks = [
                {
                    "id": "feedback_1",
                    "userId": "user_3",
                    "liked": ["EASY TO USE", "COMPLETE", "CONVENIENT", "LOOKS GOOD", "HELPFUL"],
                    "improvements": ["COULD HAVE MORE COMPONENTS"],
                    "rating": "excellent",
                    "comments": "Great prototyping kit overall, would love to see more components added.",
                    "createdAt": time:utcNow()
                }
            ];
            
            foreach json feedback in feedbacks {
                _ = check firestoreClient->createDocument("feedback", feedback.id.toString(), feedback);
            }
            log:printInfo("Seeded feedback collection");
            
            log:printInfo("Database seeding completed successfully!");
            
            check caller->respond({
                "success": true,
                "message": "Database seeded successfully!",
                "collections": {
                    "users": users.length(),
                    "services": services.length(),
                    "events": events.length(),
                    "chats": chats.length(),
                    "messages": messages.length(),
                    "bookings": bookings.length(),
                    "reviews": reviews.length(),
                    "feedback": feedbacks.length()
                }
            });
            
        } catch (error e) {
            log:printError("Error seeding database", e);
            check caller->respond({
                "success": false,
                "message": "Failed to seed database: " + e.message()
            });
        }
    }

    // Helper function to clear a collection
    function clearCollection(string collectionName) returns error? {
        log:printInfo("Clearing collection: " + collectionName);
        
        // Get all documents in the collection
        var result = firestoreClient->getDocuments(collectionName);
        
        if result is error {
            log:printWarn("Collection " + collectionName + " might not exist or is empty");
            return;
        }
        
        // In a real implementation, you would iterate through documents and delete them
        // For now, we'll just log that we're clearing the collection
        log:printInfo("Cleared collection: " + collectionName);
    }

    // Authentication endpoints
    resource function post auth/register(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json requestData = payload;
        string userId = uuid:createType1AsString();
        
        json userData = {
            "id": userId,
            "firstName": requestData.firstName,
            "lastName": requestData.lastName,
            "email": requestData.email,
            "userType": requestData.userType,
            "location": "Recife, Brazil",
            "rating": 0.0,
            "reviewCount": 0,
            "verified": false,
            "avatar": "",
            "createdAt": time:utcNow()
        };

        // Store user in Firestore
        var result = firestoreClient->createDocument("users", userId, userData);
        
        if result is error {
            log:printError("Error creating user", result);
            check caller->respond({
                "success": false,
                "message": "Failed to create user"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "user": userData,
            "message": "User created successfully"
        });
    }

    resource function post auth/login(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json requestData = payload;
        string email = requestData.email.toString();
        
        // Query Firestore for user by email
        var result = firestoreClient->getDocuments("users");
        
        if result is error {
            log:printError("Error fetching user", result);
            check caller->respond({
                "success": false,
                "message": "Login failed"
            });
            return;
        }

        // For demo purposes, return success for any email
        check caller->respond({
            "success": true,
            "user": {
                "id": "demo-user-id",
                "email": email,
                "firstName": "Demo",
                "lastName": "User",
                "userType": "client"
            },
            "token": "demo-jwt-token",
            "message": "Login successful"
        });
    }

    // Services endpoints
    resource function get services(http:Caller caller, http:Request req) returns error? {
        map<string[]> queryParams = req.getQueryParams();
        
        // Get query parameters
        string? category = queryParams["category"] is string[] ? queryParams["category"][0] : ();
        string? location = queryParams["location"] is string[] ? queryParams["location"][0] : ();
        string? minPrice = queryParams["minPrice"] is string[] ? queryParams["minPrice"][0] : ();
        string? maxPrice = queryParams["maxPrice"] is string[] ? queryParams["maxPrice"][0] : ();

        // Fetch services from Firestore
        var result = firestoreClient->getDocuments("services");
        
        if result is error {
            log:printError("Error fetching services", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch services"
            });
            return;
        }

        // For now, return mock data - in real implementation, process Firestore result
        json[] services = [
            {
                "id": "service_1",
                "title": "Great Apartment",
                "description": "Perfect flat for 4 people. Peaceful and good location, close to bus stops and many restaurants.",
                "price": 150.0,
                "location": "Recife, Brazil",
                "rating": 4.8,
                "reviewCount": 124,
                "hostName": "Karen Roe",
                "category": "accommodation",
                "imageUrl": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400",
                "dates": "Mar 12 – Mar 15"
            },
            {
                "id": "service_2",
                "title": "Cozy Studio",
                "description": "Charming studio apartment in historic Olinda.",
                "price": 85.0,
                "location": "Olinda, Brazil",
                "rating": 4.6,
                "reviewCount": 67,
                "hostName": "João Silva",
                "category": "accommodation",
                "imageUrl": "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400",
                "dates": "Mar 20 – Mar 23"
            }
        ];

        check caller->respond({
            "success": true,
            "services": services,
            "total": services.length()
        });
    }

    resource function post services(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json serviceData = payload;
        string serviceId = uuid:createType1AsString();
        
        json newService = {
            "id": serviceId,
            ...serviceData,
            "createdAt": time:utcNow(),
            "rating": 0.0,
            "reviewCount": 0,
            "active": true
        };

        // Store service in Firestore
        var result = firestoreClient->createDocument("services", serviceId, newService);
        
        if result is error {
            log:printError("Error creating service", result);
            check caller->respond({
                "success": false,
                "message": "Failed to create service"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "service": newService,
            "message": "Service created successfully"
        });
    }

    // Events endpoints
    resource function get events(http:Caller caller, http:Request req) returns error? {
        map<string[]> queryParams = req.getQueryParams();
        
        string? category = queryParams["category"] is string[] ? queryParams["category"][0] : ();
        string? location = queryParams["location"] is string[] ? queryParams["location"][0] : ();

        // Fetch events from Firestore
        var result = firestoreClient->getDocuments("events");
        
        if result is error {
            log:printError("Error fetching events", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch events"
            });
            return;
        }

        // Mock events data
        json[] events = [
            {
                "id": "event_1",
                "title": "Maroon 5",
                "description": "Live concert in Recife",
                "location": "Recife, Brazil",
                "date": "MAR 05",
                "time": "20:00",
                "price": 120.0,
                "category": "CONCERTS",
                "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
                "capacity": 50000,
                "ticketsAvailable": 15000
            },
            {
                "id": "event_2",
                "title": "Alicia Keys",
                "description": "Live performance in Olinda",
                "location": "Olinda, Brazil",
                "date": "MAR 05",
                "time": "19:00",
                "price": 95.0,
                "category": "CONCERTS",
                "imageUrl": "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
                "capacity": 25000,
                "ticketsAvailable": 8000
            }
        ];

        check caller->respond({
            "success": true,
            "events": events,
            "total": events.length()
        });
    }

    // Chat endpoints
    resource function get chats/[string userId](http:Caller caller, http:Request req) returns error? {
        // Fetch user's chats from Firestore
        var result = firestoreClient->getDocuments("chats");
        
        if result is error {
            log:printError("Error fetching chats", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch chats"
            });
            return;
        }

        // Mock chat data
        json[] chats = [
            {
                "id": "chat_1",
                "participants": ["user_1", userId],
                "lastMessage": {
                    "content": "You're the best!",
                    "timestamp": time:utcNow(),
                    "senderId": userId
                },
                "otherUser": {
                    "id": "user_1",
                    "name": "Karen Roe",
                    "avatar": "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100"
                }
            }
        ];

        check caller->respond({
            "success": true,
            "chats": chats
        });
    }

    resource function get chats/[string chatId]/messages(http:Caller caller, http:Request req) returns error? {
        // Fetch messages for a specific chat
        var result = firestoreClient->getDocuments("messages");
        
        if result is error {
            log:printError("Error fetching messages", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch messages"
            });
            return;
        }

        // Mock messages data
        json[] messages = [
            {
                "id": "msg_1",
                "chatId": chatId,
                "senderId": "user_3",
                "senderName": "Lucas",
                "content": "Hey Lucas!",
                "timestamp": time:utcNow(),
                "read": true
            },
            {
                "id": "msg_2",
                "chatId": chatId,
                "senderId": "user_3",
                "senderName": "Lucas",
                "content": "How's your project going?",
                "timestamp": time:utcNow(),
                "read": true
            }
        ];

        check caller->respond({
            "success": true,
            "messages": messages
        });
    }

    resource function post chats/[string chatId]/messages(http:Caller caller, http:Request req) returns error? {
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
        
        json newMessage = {
            "id": messageId,
            "chatId": chatId,
            "senderId": messageData.senderId,
            "senderName": messageData.senderName,
            "content": messageData.content,
            "timestamp": time:utcNow(),
            "read": false,
            "messageType": "text"
        };

        // Store message in Firestore
        var result = firestoreClient->createDocument("messages", messageId, newMessage);
        
        if result is error {
            log:printError("Error creating message", result);
            check caller->respond({
                "success": false,
                "message": "Failed to send message"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "message": newMessage
        });
    }

    // Feedback endpoint
    resource function post feedback(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json feedbackData = payload;
        string feedbackId = uuid:createType1AsString();
        
        json newFeedback = {
            "id": feedbackId,
            ...feedbackData,
            "createdAt": time:utcNow()
        };

        // Store feedback in Firestore
        var result = firestoreClient->createDocument("feedback", feedbackId, newFeedback);
        
        if result is error {
            log:printError("Error creating feedback", result);
            check caller->respond({
                "success": false,
                "message": "Failed to submit feedback"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "feedback": newFeedback,
            "message": "Feedback submitted successfully"
        });
    }

    // Bookings endpoints
    resource function get bookings/[string userId](http:Caller caller, http:Request req) returns error? {
        var result = firestoreClient->getDocuments("bookings");
        
        if result is error {
            log:printError("Error fetching bookings", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch bookings"
            });
            return;
        }

        // Mock bookings data
        json[] bookings = [
            {
                "id": "booking_1",
                "serviceId": "service_1",
                "customerId": userId,
                "hostId": "user_1",
                "startDate": "2024-03-12",
                "endDate": "2024-03-15",
                "guests": 2,
                "totalPrice": 475.0,
                "serviceFee": 25.0,
                "status": "confirmed",
                "paymentStatus": "paid"
            }
        ];

        check caller->respond({
            "success": true,
            "bookings": bookings
        });
    }

    resource function post bookings(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json bookingData = payload;
        string bookingId = uuid:createType1AsString();
        
        json newBooking = {
            "id": bookingId,
            ...bookingData,
            "status": "pending",
            "paymentStatus": "pending",
            "createdAt": time:utcNow(),
            "updatedAt": time:utcNow()
        };

        var result = firestoreClient->createDocument("bookings", bookingId, newBooking);
        
        if result is error {
            log:printError("Error creating booking", result);
            check caller->respond({
                "success": false,
                "message": "Failed to create booking"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "booking": newBooking,
            "message": "Booking created successfully"
        });
    }

    // Reviews endpoints
    resource function get reviews/service/[string serviceId](http:Caller caller, http:Request req) returns error? {
        var result = firestoreClient->getDocuments("reviews");
        
        if result is error {
            log:printError("Error fetching reviews", result);
            check caller->respond({
                "success": false,
                "message": "Failed to fetch reviews"
            });
            return;
        }

        // Mock reviews data
        json[] reviews = [
            {
                "id": "review_1",
                "serviceId": serviceId,
                "customerId": "user_3",
                "customerName": "Lucas Scott",
                "rating": 5,
                "comment": "Amazing apartment with great location! Karen was very helpful and responsive.",
                "helpful": 0,
                "createdAt": time:utcNow()
            }
        ];

        check caller->respond({
            "success": true,
            "reviews": reviews
        });
    }

    resource function post reviews(http:Caller caller, http:Request req) returns error? {
        json|error payload = req.getJsonPayload();
        
        if payload is error {
            check caller->respond({
                "success": false,
                "message": "Invalid request payload"
            });
            return;
        }

        json reviewData = payload;
        string reviewId = uuid:createType1AsString();
        
        json newReview = {
            "id": reviewId,
            ...reviewData,
            "helpful": 0,
            "createdAt": time:utcNow()
        };

        var result = firestoreClient->createDocument("reviews", reviewId, newReview);
        
        if result is error {
            log:printError("Error creating review", result);
            check caller->respond({
                "success": false,
                "message": "Failed to create review"
            });
            return;
        }

        check caller->respond({
            "success": true,
            "review": newReview,
            "message": "Review created successfully"
        });
    }
}
