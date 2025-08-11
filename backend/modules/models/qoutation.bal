import ballerina/persist as _;

// Main Quotation entity
public type Quotation record {|
    readonly string id;           // Unique quotation identifier
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
    string validUntil;            // Quotation expiry date (ISO 8601 format)
    string createdAt;             // Creation timestamp (ISO 8601 format)
    string updatedAt;             // Last update timestamp (ISO 8601 format)
    string? acceptedAt;           // When client accepted (ISO 8601 format)
    string? rejectedAt;           // When client rejected (ISO 8601 format)
    QuotationHistory[] history;   // Status change history
|};

// Detailed quotation information
public type QuotationDetails record {|
    string description;           // Detailed work description
    string[] workScope;           // Scope of work items
    string[] deliverables;        // What will be delivered
    int estimatedHours;           // Estimated work duration in hours
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
|};

// Pricing breakdown
public type PricingBreakdown record {|
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
|};

// Terms and conditions
public type QuotationTerms record {|
    string[] conditions;          // Terms and conditions
    string warrantyPeriod;        // Warranty/guarantee period
    string cancellationPolicy;   // Cancellation policy
    string revisionPolicy;        // How many revisions included
    string[] responsibilities;    // Provider responsibilities
    string[] clientResponsibilities; // Client responsibilities
    string disputeResolution;     // Dispute resolution process
    string liability;             // Liability terms
|};

// Quotation history for tracking changes
public type QuotationHistory record {|
    string action;                // "created", "updated", "accepted", "rejected", etc.
    string performedBy;           // User ID who performed the action
    string timestamp;             // When action was performed (ISO 8601 format)
    string? reason;               // Reason for status change
    map<json>? previousData;      // Previous state data
    map<json>? newData;           // New state data
|};

// Quotation creation request model
public type QuotationCreation record {|
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
|};

// Quotation update request model
public type QuotationUpdate record {|
    string? status;
    string? description;
    string[]? workScope;
    decimal? basePrice;
    decimal? totalAmount;
    string? timeline;
    string? notes;
    string? reason;
|};

// Response models
public type QuotationResponse record {|
    string id;
    string requestId;
    string serviceId;
    string serviceTitle;
    string providerId;
    string providerEmail;
    string clientId;
    string clientEmail;
    string status;
    QuotationDetails details;
    PricingBreakdown pricing;
    QuotationTerms terms;
    string validUntil;
    string createdAt;
    string updatedAt;
    string? acceptedAt;
    string? rejectedAt;
    QuotationHistory[] history;
|};

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

// Helper methods
public function Quotation.isPending() returns boolean {
    return self.status == "pending";
}

public function Quotation.isAccepted() returns boolean {
    return self.status == "accepted";
}

public function Quotation.isRejected() returns boolean {
    return self.status == "rejected";
}

public function Quotation.isExpired() returns boolean {
    return self.status == "expired";
}

public function Quotation.isWithdrawn() returns boolean {
    return self.status == "withdrawn";
}

// Validation functions
public function validateQuotationStatus(string status) returns boolean {
    string[] validStatuses = ["pending", "accepted", "rejected", "expired", "withdrawn"];
    return validStatuses.indexOf(status) != ();
}

public function validateWorkType(string workType) returns boolean {
    string[] validTypes = ["one_time", "recurring", "project_based"];
    return validTypes.indexOf(workType) != ();
}

public function validateUrgencyLevel(string urgencyLevel) returns boolean {
    string[] validLevels = ["low", "medium", "high", "urgent"];
    return validLevels.indexOf(urgencyLevel) != ();
}