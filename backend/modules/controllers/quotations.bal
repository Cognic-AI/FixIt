import backend.models;

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

// Quotation model types
public type Quotation record {
    string id;                    // Unique quotation identifier
    string requestId;             // Reference to the service request
    string serviceId;             // Reference to the original service
    string serviceTitle;          // Service title for quick reference
    string providerId;            // Provider who created the quotation
    string providerEmail;         // Provider email
    string clientId;              // Client who will receive the quotation
    string clientEmail;           // Client email
    string status;                // "pending", "accepted", "rejected", "expired", "withdrawn"
    QuotationDetails details;     // Detailed quotation information
    PricingBreakdown pricing;     // Pricing breakdown
    QuotationTerms terms;         // Terms and conditions
    string validUntil;            // Quotation expiry date
    string createdAt;             // Creation timestamp
    string updatedAt;             // Last update timestamp
    string? acceptedAt;           // When client accepted
    string? rejectedAt;           // When client rejected
    QuotationHistory[] history;   // Status change history
};

// Detailed quotation information
public type QuotationDetails record {
    string description;           // Detailed work description
    string[] workScope;           // Scope of work items
    string[] deliverables;        // What will be delivered
    int estimatedHours;           // Estimated work duration
    string timeline;              // Expected completion timeline
    string[] requirements;        // Client requirements addressed
    string[] assumptions;         // Assumptions made in the quote
    string[] exclusions;          // What's not included
    string location;              // Work location
    boolean isRemote;             // Can work be done remotely
    string workType;              // "one_time", "recurring", "project_based"
    string urgencyLevel;          // "low", "medium", "high", "urgent"
    string[] materialsIncluded;  // Materials included in quote
    string[] toolsRequired;      // Tools provider will bring
    string? notes;               // Additional notes from provider
    string[] attachments;        // File URLs (images, documents)
};

// Pricing breakdown
public type PricingBreakdown record {
    decimal basePrice;            // Base service price
    decimal laborCost;            // Labor cost
    decimal materialCost;         // Materials cost (if any)
    decimal transportCost;        // Transportation cost (if any)
    decimal additionalCharges;    // Any additional charges
    decimal discountAmount;       // Discount applied (if any)
    decimal taxAmount;            // Tax amount
    decimal totalAmount;          // Final total amount
    string currency;              // Currency (e.g., "LKR", "USD")
    string paymentMethod;         // Preferred payment method
    decimal advancePayment;       // Required advance payment
    string[] paymentTerms;        // Payment terms
    boolean negotiable;           // Whether price is negotiable
};

// Terms and conditions
public type QuotationTerms record {
    string[] conditions;          // Terms and conditions
    string warrantyPeriod;        // Warranty/guarantee period
    string cancellationPolicy;   // Cancellation policy
    string revisionPolicy;        // How many revisions included
    string[] responsibilities;    // Provider responsibilities
    string[] clientResponsibilities; // Client responsibilities
    string disputeResolution;     // Dispute resolution process
    string liability;             // Liability terms
};

// Quotation history for tracking changes
public type QuotationHistory record {
    string action;                // "created", "updated", "accepted", "rejected", etc.
    string performedBy;           // User ID who performed the action
    string timestamp;             // When action was performed
    string? reason;               // Reason for status change
    map<json>? previousData;      // Previous state data
    map<json>? newData;           // New state data
};

// Quotation creation request model
public type QuotationCreation record {
    string requestId;
    string description;
    string[] workScope;
    string[] deliverables;
    int estimatedHours;
    string timeline;
    string[] requirements;
    string[] assumptions;
    string[] exclusions;
    string location;
    boolean isRemote;
    string workType;
    string urgencyLevel;
    string[] materialsIncluded;
    string[] toolsRequired;
    decimal basePrice;
    decimal laborCost;
    decimal materialCost;
    decimal transportCost;
    decimal additionalCharges;
    decimal discountAmount;
    decimal taxAmount;
    string paymentMethod;
    decimal advancePayment;
    string[] paymentTerms;
    boolean negotiable;
    string[] conditions;
    string warrantyPeriod;
    string cancellationPolicy;
    string revisionPolicy;
    int validityDays;             // How many days the quote is valid
    string? notes;
};

// Quotation update request model
public type QuotationUpdate record {
    string? status;
    string? description;
    string[]? workScope;
    decimal? basePrice;
    decimal? totalAmount;
    string? timeline;
    string? notes;
    string? reason;
};

// Create a new quotation (Provider only)
public function createQuotation(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize provider role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only service providers can create quotations",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json|error payload = req.getJsonPayload();
    if payload is error {
        json errorResponse = {
            "message": "Invalid request payload",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    QuotationCreation|error quotationData = payload.cloneWithType(QuotationCreation);
    if quotationData is error {
        json errorResponse = {
            "message": "Invalid quotation data format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get request details to validate and get client info
    map<json> requestFilter = {"id": quotationData.requestId};
    models:RequestResponse|error requestData = models:queryRequest(requestFilter);
    if requestData is error {
        json errorResponse = {
            "message": "Request not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Verify that the provider is authorized for this request
    if requestData.providerId != user.id {
        json errorResponse = {
            "message": "Unauthorized: You can only create quotations for your own services",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Calculate total amount
    decimal totalAmount = quotationData.basePrice + quotationData.laborCost + 
                         quotationData.materialCost + quotationData.transportCost + 
                         quotationData.additionalCharges + quotationData.taxAmount - 
                         quotationData.discountAmount;

    // Create quotation object
    string quotationId = uuid:createType1AsString();
    string currentTime = time:utcToString(time:utcNow());
    
    // Calculate validity date
    time:Utc validUntilTime = time:utcAddSeconds(time:utcNow(), quotationData.validityDays * 24 * 3600);
    string validUntil = time:utcToString(validUntilTime);

    QuotationHistory initialHistory = {
        action: "created",
        performedBy: user.id,
        timestamp: currentTime,
        reason: "Quotation created by provider",
        previousData: (),
        newData: ()
    };

    Quotation newQuotation = {
        id: quotationId,
        requestId: quotationData.requestId,
        serviceId: requestData.serviceId,
        serviceTitle: requestData.title,
        providerId: user.id,
        providerEmail: user.email,
        clientId: requestData.clientId,
        clientEmail: requestData.clientEmail,
        status: "pending",
        details: {
            description: quotationData.description,
            workScope: quotationData.workScope,
            deliverables: quotationData.deliverables,
            estimatedHours: quotationData.estimatedHours,
            timeline: quotationData.timeline,
            requirements: quotationData.requirements,
            assumptions: quotationData.assumptions,
            exclusions: quotationData.exclusions,
            location: quotationData.location,
            isRemote: quotationData.isRemote,
            workType: quotationData.workType,
            urgencyLevel: quotationData.urgencyLevel,
            materialsIncluded: quotationData.materialsIncluded,
            toolsRequired: quotationData.toolsRequired,
            notes: quotationData.notes,
            attachments: []
        },
        pricing: {
            basePrice: quotationData.basePrice,
            laborCost: quotationData.laborCost,
            materialCost: quotationData.materialCost,
            transportCost: quotationData.transportCost,
            additionalCharges: quotationData.additionalCharges,
            discountAmount: quotationData.discountAmount,
            taxAmount: quotationData.taxAmount,
            totalAmount: totalAmount,
            currency: "LKR",
            paymentMethod: quotationData.paymentMethod,
            advancePayment: quotationData.advancePayment,
            paymentTerms: quotationData.paymentTerms,
            negotiable: quotationData.negotiable
        },
        terms: {
            conditions: quotationData.conditions,
            warrantyPeriod: quotationData.warrantyPeriod,
            cancellationPolicy: quotationData.cancellationPolicy,
            revisionPolicy: quotationData.revisionPolicy,
            responsibilities: [],
            clientResponsibilities: [],
            disputeResolution: "Standard dispute resolution applies",
            liability: "Standard liability terms apply"
        },
        validUntil: validUntil,
        createdAt: currentTime,
        updatedAt: currentTime,
        acceptedAt: (),
        rejectedAt: (),
        history: [initialHistory]
    };

    // Save quotation to MongoDB
    string|error createResult = check models:createDocument("quotations", mapToJSON(newQuotation.toJson()));
    if createResult is error {
        log:printError("Failed to create quotation in MongoDB", createResult);
        json errorResponse = {
            "message": "Failed to create quotation",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Quotation created successfully",
        "quotation": newQuotation.toJson()
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Quotation created successfully by provider: " + user.email);
}

// Helper function to convert Quotation record to JSON
function mapToJSON(map<json> data) returns map<json> {
    return data;
}

// Extension methods for Quotation record
public function Quotation.toJson() returns map<json> {
    return {
        "id": self.id,
        "requestId": self.requestId,
        "serviceId": self.serviceId,
        "serviceTitle": self.serviceTitle,
        "providerId": self.providerId,
        "providerEmail": self.providerEmail,
        "clientId": self.clientId,
        "clientEmail": self.clientEmail,
        "status": self.status,
        "details": self.details,
        "pricing": self.pricing,
        "terms": self.terms,
        "validUntil": self.validUntil,
        "createdAt": self.createdAt,
        "updatedAt": self.updatedAt,
        "acceptedAt": self.acceptedAt,
        "rejectedAt": self.rejectedAt,
        "history": self.history
    };
}

// Accept quotation (Client only)
public function acceptQuotation(http:Caller caller, http:Request req, string quotationId) returns error? {
    // Authenticate and authorize client role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only clients can accept quotations",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Implementation for accepting quotation would go here
    // This would update the quotation status and create a contract
    
    json successResponse = {
        "message": "Quotation accepted successfully"
    };
    
    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}

// Get quotations for a provider
public function getProviderQuotations(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize provider role
    models:User|error user = authorizeRole(req, ["vendor"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Implementation to get quotations would go here
    
    json successResponse = {
        "quotations": []
    };
    
    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}