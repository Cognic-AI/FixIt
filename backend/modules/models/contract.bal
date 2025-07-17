import ballerina/io;
import ballerina/time;
import ballerinax/mongodb;
import backend.utils;

// Contract model for storing work agreements/gigs
public type Contract record {
    string id;                    // Unique contract identifier
    string serviceId;             // Reference to the service being contracted
    string serviceTitle;          // Service title for quick reference
    string customerId;            // Customer who created the contract
    string customerEmail;         // Customer email
    string providerId;            // Service provider
    string providerEmail;         // Provider email
    string status;                // "pending", "accepted", "rejected", "in_progress", "completed", "cancelled", "disputed"
    ContractTerms terms;          // Contract terms and conditions
    PaymentInfo payment;          // Payment related information
    WorkSchedule schedule;        // Work timeline and schedule
    ContractDetails? details;      // Additional contract details
    string createdAt;             // Contract creation timestamp
    string updatedAt;             // Last update timestamp
    string? acceptedAt;           // When provider accepted
    string? startedAt;            // When work started
    string? completedAt;          // When work completed
    ContractHistory[] history;    // Status change history
};

// Contract terms and conditions
public type ContractTerms record {
    string description;           // Detailed work description
    string[] requirements;        // Specific requirements/deliverables
    decimal agreedPrice;          // Final agreed price
    string currency;              // Currency (e.g., "LKR", "USD")
    string paymentMethod;         // "cash", "bank_transfer", "digital_wallet"
    int estimatedHours;           // Estimated work duration in hours
    string[]? milestones;          // Work milestones if applicable
    string cancellationPolicy;   // Cancellation terms
    string? warrantyPeriod;        // Warranty/guarantee period
};

// Payment information
public type PaymentInfo record {
    decimal totalAmount;          // Total contract amount
    decimal? advancePayment;       // Advance payment amount
    decimal? remainingAmount;      // Remaining amount after advance
    string paymentStatus;         // "pending", "advance_paid", "partially_paid", "fully_paid", "refunded"
    PaymentTransaction[]? transactions; // Payment transaction history
    string? invoiceUrl;           // Invoice document URL
    string? receiptUrl;           // Payment receipt URL
};

// Payment transaction record
public type PaymentTransaction record {
    string id;                    // Transaction ID
    decimal amount;               // Payment amount
    string transactionType;       // "advance", "milestone", "final", "refund"
    string paymentMethod;         // Payment method used
    string status;                // "pending", "completed", "failed"
    string timestamp;             // Transaction timestamp
    string? referenceNumber;      // Bank/payment gateway reference
};

// Work schedule and timeline
public type WorkSchedule record {
    string startDate;             // Planned start date
    string endDate;               // Planned completion date
    string[] workingDays;         // ["monday", "tuesday", ...] or ["everyday"]
    string preferredTimeSlot;     // "morning", "afternoon", "evening", "flexible"
    string specificTime;          // Specific time if applicable (e.g., "09:00-17:00")
    boolean isFlexible;           // Whether schedule is flexible
    string location;              // Work location
    boolean isRemote;             // Can work be done remotely
};

// Additional contract details
public type ContractDetails record {
    string workType;              // "one_time", "recurring", "project_based"
    string urgencyLevel;          // "low", "medium", "high", "urgent"
    string[]? skillsRequired;      // Required skills for the work
    string[]? materialsProvided;   // Materials provided by customer
    string[]? toolsRequired;       // Tools provider needs to bring
    string[]? safetyRequirements;  // Safety requirements if applicable
    string? notes;                // Additional notes from customer
    string? providerNotes;        // Notes from provider
    string[]? attachments;         // File URLs (images, documents)
};

// Contract history for tracking changes
public type ContractHistory record {
    string action;                // "created", "updated", "accepted", "rejected", etc.
    string performedBy;           // User ID who performed the action
    string timestamp;             // When action was performed
    string? reason;               // Reason for status change
    map<json>? previousData;      // Previous state data
    map<json>? newData;           // New state data
};

// Contract creation request model
public type ContractCreation record {
    string serviceId;
    string description;
    string[] requirements;
    decimal proposedPrice;
    string paymentMethod;
    int? estimatedHours;
    string startDate;
    string? endDate;
    string[] workingDays;
    string? preferredTimeSlot;
    string location;
    boolean isRemote;
    string? workType;
    string urgencyLevel;
    string[]? skillsRequired;
    string[]? materialsProvided;
    string[]? toolsRequired;
    decimal? advancePayment;
    string? notes;
};

// Contract update request model
public type ContractUpdate record {
    string? description;
    string[]? requirements;
    decimal? proposedPrice;
    string? startDate;
    string? endDate;
    string[]? workingDays;
    string? location;
    string? notes;
    string? status;
};

// Query functions for Contract operations

// Get contract by ID
public function queryContract(map<json> filter) returns Contract|error {
    string collection = "contracts";
    io:println("🔍 Getting contract from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    Contract|mongodb:Error|() result = mongoCollection->findOne(
        filter,
        {},
        (),
        Contract
    );

    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    } else if result is () {
        io:println("❌ No contract found matching the filter");
        return error("Contract not found");
    } else {
        io:println("✅ Contract retrieved successfully");
        return result;
    }
}

// Get contracts with filters (for listing)
public function queryContracts(map<json> filter) returns Contract[]|error {
    string collection = "contracts";
    io:println("🔍 Querying contracts from collection: ", collection);

    mongodb:Database db = check utils:mongoDb->getDatabase("main");
    mongodb:Collection mongoCollection = check db->getCollection(collection);

    io:println("📋 Using filter: ", filter.toString());
    io:println("🚀 Executing query...");

    stream<Contract, error?>|mongodb:Error result = check mongoCollection->find(
        filter,
        {},
        (),
        Contract
    );

    if result is mongodb:Error {
        io:println("❌ Error executing query: ", result.message());
        return error("MongoDB error: " + result.message());
    }

    Contract[] contracts = [];
    error? e = result.forEach(function(Contract contract) {
        contracts.push(contract);
    });

    if e is error {
        io:println("❌ Error processing stream: ", e.message());
        return error("Stream processing error: " + e.message());
    }

    if contracts.length() == 0 {
        io:println("⚠️ No contracts found matching the filter");
        return [];
    }

    io:println("✅ Retrieved ", contracts.length(), " contracts successfully");
    return contracts;
}

// Get contracts by user (customer or provider)
public function getContractsByUser(string userId, string userType) returns Contract[]|error {
    map<json> filter = {};
    
    if userType == "client" {
        filter = {"customerId": userId};
    } else if userType == "vendor" {
        filter = {"providerId": userId};
    } else {
        return error("Invalid user type. Must be 'customer' or 'provider'");
    }

    return queryContracts(filter);
}

// Get contracts by status
public function getContractsByStatus(string status) returns Contract[]|error {
    map<json> filter = {"status": status};
    return queryContracts(filter);
}

// Get active contracts for a provider
public function getActiveContractsForProvider(string providerId) returns Contract[]|error {
    map<json> filter = {
        "providerId": providerId,
        "status": {"$in": ["accepted", "in_progress"]}
    };
    return queryContracts(filter);
}

// Utility function to create contract history entry
public function createHistoryEntry(string action, string performedBy, string? reason = ()) returns ContractHistory {
    return {
        action: action,
        performedBy: performedBy,
        timestamp: time:utcToString(time:utcNow()),
        reason: reason,
        previousData: (),
        newData: ()
    };
}