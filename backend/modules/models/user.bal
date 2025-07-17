public type User record {
    string id;
    string email;
    string firstName;
    string lastName;
    string? phoneNumber;
    string role; // "customer", "provider", "admin"
    string password; // hashed
    boolean emailVerified;
    string? profileImageUrl;
    string createdAt;
    string updatedAt;
    string? lastLoginAt;
}; // Initialize MongoDB client


