# FixIt Authentication System

This document explains how to use the Firestore-based authentication system with JWT tokens for the FixIt application.

## Overview

The authentication system provides:
- User registration and login using Firestore
- JWT token generation and verification
- Role-based access control (customer, provider, admin)
- Middleware for protecting routes
- Password hashing and verification

## Authentication Flow

### 1. User Registration
**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890", // optional
  "role": "customer" // or "provider"
}
```

**Response:**
```json
{
  "token": "fixit.eyJ1c2VySWQi...",
  "user": {
    "id": "user-uuid",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "customer",
    "emailVerified": false,
    "createdAt": "2025-07-13T10:30:00Z"
  },
  "message": "User registered successfully"
}
```

### 2. User Login
**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:** Same as registration response

### 3. Get User Profile
**Endpoint:** `GET /api/auth/profile`

**Headers:**
```
Authorization: Bearer fixit.eyJ1c2VySWQi...
```

**Response:**
```json
{
  "id": "user-uuid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "customer",
  "emailVerified": false,
  "createdAt": "2025-07-13T10:30:00Z",
  "lastLoginAt": "2025-07-13T11:00:00Z"
}
```

## Using Authentication Middleware

### 1. Basic Authentication
Use `auth:authenticateRequest()` to verify that a user is logged in:

```ballerina
public isolated function protectedEndpoint(http:Caller caller, http:Request req) returns error? {
    auth:User|error user = auth:authenticateRequest(req);
    if user is error {
        json errorResponse = {
            "message": "Unauthorized: " + user.message(),
            "statusCode": 401
        };
        http:Response response = new;
        response.statusCode = 401;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // User is authenticated, proceed with endpoint logic
    // Access user data: user.id, user.email, user.role, etc.
}
```

### 2. Role-Based Authorization
Use `auth:authorizeRole()` to restrict access to specific roles:

```ballerina
public isolated function providerOnlyEndpoint(http:Caller caller, http:Request req) returns error? {
    auth:User|error user = auth:authorizeRole(req, ["provider"]);
    if user is error {
        json errorResponse = {
            "message": "Forbidden: " + user.message(),
            "statusCode": 403
        };
        http:Response response = new;
        response.statusCode = 403;
        response.setJsonPayload(errorResponse);
        check caller->respond(response);
        return;
    }

    // User is authenticated and has provider role
    // Proceed with provider-specific logic
}
```

### 3. Multiple Role Authorization
```ballerina
// Allow both providers and admins
auth:User|error user = auth:authorizeRole(req, ["provider", "admin"]);
```

## JWT Token Format

The system uses a custom JWT-like token format for simplicity:
- Format: `fixit.{base64payload}.{signature}`
- Payload contains: userId, email, role, firstName, lastName, expiration
- Signature is SHA-256 hash for verification

## Firestore Data Structure

### Users Collection
Document ID: User's email address
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "phoneNumber": "+1234567890",
  "role": "customer",
  "password": "hashed_password",
  "emailVerified": false,
  "profileImageUrl": null,
  "createdAt": "2025-07-13T10:30:00Z",
  "updatedAt": "2025-07-13T10:30:00Z",
  "lastLoginAt": "2025-07-13T11:00:00Z"
}
```

## Example Usage in Service Modules

See `backend/modules/services/services.bal` for complete examples of:
- Creating services (provider only)
- Getting all services (public, with optional auth info)
- Getting user's own services (provider only)
- Updating services (provider only, own services)
- Deleting services (provider only, own services)

## Security Considerations

1. **Password Security**: Passwords are hashed using SHA-256
2. **Token Expiration**: Tokens expire after 24 hours by default
3. **Role-Based Access**: Strict role checking for sensitive operations
4. **Ownership Validation**: Users can only modify their own resources

## Configuration

Update these values in `backend/modules/auth/auth.bal`:
```ballerina
configurable string jwtSecretKey = "your-super-secret-jwt-key-change-this-in-production";
configurable int jwtExpirationTime = 86400; // 24 hours in seconds
```

## Error Responses

All endpoints return consistent error responses:
```json
{
  "message": "Error description",
  "statusCode": 400/401/403/404/500
}
```

## Testing Authentication

1. **Register a new user:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123","firstName":"Test","lastName":"User","role":"provider"}'
   ```

2. **Login:**
   ```bash
   curl -X POST http://localhost:8080/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password123"}'
   ```

3. **Access protected endpoint:**
   ```bash
   curl -X GET http://localhost:8080/api/auth/profile \
     -H "Authorization: Bearer YOUR_TOKEN_HERE"
   ```

4. **Test role-based access:**
   ```bash
   curl -X POST http://localhost:8080/api/services \
     -H "Authorization: Bearer YOUR_PROVIDER_TOKEN_HERE" \
     -H "Content-Type: application/json" \
     -d '{"title":"Test Service","description":"A test service","category":"testing","price":50.0,"tags":["test"],"images":[],"location":"Test City"}'
   ```
