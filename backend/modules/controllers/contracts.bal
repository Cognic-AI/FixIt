import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;

import backend.models;

// Import contract types from models
public type Contract record {
    string id;
    string serviceId;
    string serviceTitle;
    string customerId;
    string customerEmail;
    string providerId;
    string providerEmail;
    string status; // "pending", "accepted", "rejected", "in_progress", "completed", "cancelled", "disputed"
    ContractTerms terms;
    PaymentInfo payment;
    WorkSchedule schedule;
    ContractDetails details;
    string createdAt;
    string updatedAt;
    string? acceptedAt;
    string? startedAt;
    string? completedAt;
    ContractHistory[] history;
};

public type ContractTerms record {
    string description;
    string[] requirements;
    decimal agreedPrice;
    string currency;
    string paymentMethod;
    int estimatedHours;
    string[] milestones;
    string cancellationPolicy;
    string warrantyPeriod;
};

public type PaymentInfo record {
    decimal totalAmount;
    decimal advancePayment;
    decimal remainingAmount;
    string paymentStatus; // "pending", "advance_paid", "partially_paid", "fully_paid", "refunded"
    PaymentTransaction[] transactions;
    string? invoiceUrl;
    string? receiptUrl;
};

public type PaymentTransaction record {
    string id;
    decimal amount;
    string transactionType; // "advance", "milestone", "final", "refund"
    string paymentMethod;
    string status; // "pending", "completed", "failed"
    string timestamp;
    string? referenceNumber;
};

public type WorkSchedule record {
    string startDate;
    string endDate;
    string[] workingDays;
    string preferredTimeSlot;
    string specificTime;
    boolean isFlexible;
    string location;
    boolean isRemote;
};

public type ContractDetails record {
    string workType; // "one_time", "recurring", "project_based"
    string urgencyLevel; // "low", "medium", "high", "urgent"
    string[] skillsRequired;
    string[] materialsProvided;
    string[] toolsRequired;
    string[] safetyRequirements;
    string? notes;
    string? providerNotes;
    string[] attachments;
};

public type ContractHistory record {
    string action;
    string performedBy;
    string timestamp;
    string? reason;
    map<json>? previousData;
    map<json>? newData;
};

public type ContractCreation record {
    string serviceId;
    string description;
    string[] requirements;
    decimal proposedPrice;
    string paymentMethod;
    int estimatedHours;
    string startDate;
    string endDate;
    string[] workingDays;
    string preferredTimeSlot;
    string location;
    boolean isRemote;
    string workType;
    string urgencyLevel;
    string[] skillsRequired;
    string[] materialsProvided;
    string[] toolsRequired;
    decimal advancePayment;
    string? notes;
};

public type ContractUpdate record {
    string? status;
    string? description;
    string[]? requirements;
    decimal? proposedPrice;
    string? startDate;
    string? endDate;
    string[]? workingDays;
    string? location;
    string? notes;
    string? reason;
};

// Create a new contract (Customer only)
public function createContract(http:Caller caller, http:Request req) returns error? {
    // Authenticate and authorize customer role
    models:User|error user = authorizeRole(req, ["client"]);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Only customers can create contracts",
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

    ContractCreation|error contractData = payload.cloneWithType(ContractCreation);
    if contractData is error {
        json errorResponse = {
            "message": "Invalid contract data format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get service details to validate and get provider info
    map<json> serviceFilter = {"id": contractData.serviceId};
    models:_Service|error serviceData = models:queryService(serviceFilter);
    if serviceData is error {
        json errorResponse = {
            "message": "Service not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Create contract object
    string contractId = uuid:createType1AsString();
    string currentTime = time:utcToString(time:utcNow());

    ContractHistory initialHistory = {
        action: "created",
        performedBy: user.id,
        timestamp: currentTime,
        reason: "Contract created by customer",
        previousData: (),
        newData: ()
    };

    Contract newContract = {
        id: contractId,
        serviceId: contractData.serviceId,
        serviceTitle: serviceData.title,
        customerId: user.id,
        customerEmail: user.email,
        providerId: serviceData.providerId,
        providerEmail: serviceData.providerEmail,
        status: "pending",
        terms: {
            description: contractData.description,
            requirements: contractData.requirements,
            agreedPrice: contractData.proposedPrice,
            currency: "LKR",
            paymentMethod: contractData.paymentMethod,
            estimatedHours: contractData.estimatedHours,
            milestones: [],
            cancellationPolicy: "Standard cancellation policy applies",
            warrantyPeriod: "30 days"
        },
        payment: {
            totalAmount: contractData.proposedPrice,
            advancePayment: contractData.advancePayment,
            remainingAmount: contractData.proposedPrice - contractData.advancePayment,
            paymentStatus: "pending",
            transactions: [],
            invoiceUrl: (),
            receiptUrl: ()
        },
        schedule: {
            startDate: contractData.startDate,
            endDate: contractData.endDate,
            workingDays: contractData.workingDays,
            preferredTimeSlot: contractData.preferredTimeSlot,
            specificTime: "",
            isFlexible: true,
            location: contractData.location,
            isRemote: contractData.isRemote
        },
        details: {
            workType: contractData.workType,
            urgencyLevel: contractData.urgencyLevel,
            skillsRequired: contractData.skillsRequired,
            materialsProvided: contractData.materialsProvided,
            toolsRequired: contractData.toolsRequired,
            safetyRequirements: [],
            notes: contractData.notes,
            providerNotes: (),
            attachments: []
        },
        createdAt: currentTime,
        updatedAt: currentTime,
        acceptedAt: (),
        startedAt: (),
        completedAt: (),
        history: [initialHistory]
    };

    // Save contract to MongoDB
    string|error createResult = check models:createDocument("contracts", mapToJSON(newContract.toJson()));
    if createResult is error {
        log:printError("Failed to create contract in MongoDB", createResult);
        json errorResponse = {
            "message": "Failed to create contract",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Contract created successfully",
        "contract": newContract.toJson()
    };

    http:Response response = new;
    response.statusCode = 201;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Contract created successfully by customer: " + user.email);
}

// Get user's contracts (Customer gets their contracts, Provider gets contracts for their services)
public function getMyContracts(http:Caller caller, http:Request req) returns error? {
    // Authenticate user
    models:User|error user = authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Authentication required",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filter = {};
    if user.role == "customer" {
        filter = {"customerId": user.id};
    } else if user.role == "vendor" {
        filter = {"providerId": user.id};
    } else {
        json errorResponse = {
            "message": "Forbidden: Invalid user role",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    models:Contract[]|error contractsData = models:queryContracts(filter);
    if contractsData is error {
        log:printError("Failed to fetch contracts from MongoDB", contractsData);
        json errorResponse = {
            "message": "Failed to fetch contracts",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Contracts retrieved successfully",
        "contracts": contractsData.toJson(),
        "userRole": user.role
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}

// Get contract by ID
public function getContract(http:Caller caller, http:Request req, string contractId) returns error? {
    // Authenticate user
    models:User|error user = authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Authentication required",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filter = {"id": contractId};
    models:Contract|error contractData = models:queryContract(filter);
    if contractData is error {
        json errorResponse = {
            "message": "Contract not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Check if user has access to this contract
    if contractData.customerId != user.id && contractData.providerId != user.id {
        json errorResponse = {
            "message": "Forbidden: You don't have access to this contract",
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Contract retrieved successfully",
        "contract": contractData.toJson()
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}

// Update contract status (Provider can accept/reject, both can update to in_progress/completed)
public function updateContractStatus(http:Caller caller, http:Request req, string contractId) returns error? {
    // Authenticate user
    models:User|error user = authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Authentication required",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Get existing contract
    map<json> filter = {"id": contractId};
    models:Contract|error existingContract = models:queryContract(filter);
    if existingContract is error {
        json errorResponse = {
            "message": "Contract not found",
            "statusCode": 404
        };
        http:Response response = new;
        response.statusCode = 404;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Check if user has access to this contract
    if existingContract.customerId != user.id && existingContract.providerId != user.id {
        json errorResponse = {
            "message": "Forbidden: You don't have access to this contract",
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

    ContractUpdate|error updateData = payload.cloneWithType(ContractUpdate);
    if updateData is error {
        json errorResponse = {
            "message": "Invalid update data format",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    string? newStatus = updateData.status;
    if newStatus is () {
        json errorResponse = {
            "message": "Status is required for update",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // Validate status transitions and permissions
    boolean isValidTransition = validateStatusTransition(existingContract.status, newStatus, user, <Contract>existingContract);
    if !isValidTransition {
        json errorResponse = {
            "message": "Invalid status transition or insufficient permissions",
            "statusCode": 400
        };
        http:Response response = new;
        response.statusCode = 400;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    string currentTime = time:utcToString(time:utcNow());
    
    // Create history entry
    ContractHistory historyEntry = {
        action: "status_updated",
        performedBy: user.id,
        timestamp: currentTime,
        reason: updateData.reason,
        previousData: {"status": existingContract.status},
        newData: {"status": newStatus}
    };

    // Update contract
    existingContract.status = newStatus;
    existingContract.updatedAt = currentTime;
    existingContract.history.push(historyEntry);

    // Set specific timestamps based on status
    if newStatus == "accepted" {
        existingContract.acceptedAt = currentTime;
    } else if newStatus == "in_progress" {
        existingContract.startedAt = currentTime;
    } else if newStatus == "completed" {
        existingContract.completedAt = currentTime;
    }

    // Update in MongoDB
    error? updateResult = models:updateDocument("contracts", contractId, mapToJSON(existingContract.toJson()));
    if updateResult is error {
        log:printError("Failed to update contract in MongoDB", updateResult);
        json errorResponse = {
            "message": "Failed to update contract",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Contract status updated successfully",
        "contract": existingContract.toJson()
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
    log:printInfo("Contract status updated: " + contractId + " to " + newStatus);
}

// Get contracts by status
public function getContractsByStatus(http:Caller caller, http:Request req, string status) returns error? {
    // Authenticate user
    models:User|error user = authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: Authentication required",
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    map<json> filter = {"status": status};
    
    // Add user-specific filter
    if user.role == "customer" {
        filter["customerId"] = user.id;
    } else if user.role == "vendor" {
        filter["providerId"] = user.id;
    }

    models:Contract[]|error contractsData = models:queryContracts(filter);
    if contractsData is error {
        log:printError("Failed to fetch contracts by status from MongoDB", contractsData);
        json errorResponse = {
            "message": "Failed to fetch contracts",
            "statusCode": 500
        };
        http:Response response = new;
        response.statusCode = 500;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    json successResponse = {
        "message": "Contracts retrieved successfully",
        "contracts": contractsData.toJson(),
        "status": status,
        "userRole": user.role
    };

    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}

// Utility function to validate status transitions
function validateStatusTransition(string currentStatus, string newStatus, models:User user, Contract contract) returns boolean {
    // Only provider can accept/reject pending contracts
    if currentStatus == "pending" && (newStatus == "accepted" || newStatus == "rejected") {
        return user.id == contract.providerId;
    }
    
    // Both parties can start work if accepted
    if currentStatus == "accepted" && newStatus == "in_progress" {
        return user.id == contract.customerId || user.id == contract.providerId;
    }
    
    // Both parties can complete work
    if currentStatus == "in_progress" && newStatus == "completed" {
        return user.id == contract.customerId || user.id == contract.providerId;
    }
    
    // Both parties can cancel at any time before completion
    if newStatus == "cancelled" && currentStatus != "completed" {
        return user.id == contract.customerId || user.id == contract.providerId;
    }
    
    // Both parties can dispute
    if newStatus == "disputed" {
        return user.id == contract.customerId || user.id == contract.providerId;
    }
    
    return false;
}

