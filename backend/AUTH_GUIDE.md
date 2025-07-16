# FixIt Authentication System

This document explains how to use the Firestore-based authentication system with JWT tokens for the FixIt application.

## Overview

The authentication system provides:
- User registration and login using Firestore
- JWT token generation and verification
- Role-based access control (customer, provider, admin)
- Middleware for protecting routes
- Password hashing and verification

## API Endpoints

The authentication service runs on port 8080 with the following endpoints:

- **Base URL**: `http://localhost:8080/api/auth`
- **Health Check**: `http://localhost:8083/api/health`
- **Admin Endpoints**: `http://localhost:8081/api/admin`
- **AI Chat**: `http://localhost:8082/api/ai`

## Authentication Flow

### 1. User Registration
**Endpoint:** `POST /api/auth/register`

**Request Body:**
```json
{
  "email": "test@fixit.lk",
  "password": "securepassword123",
  "firstName": "Sahan",
  "lastName": "Lahiru",
  "phoneNumber": "0765820661",
  "role": "customer"
}
```

**Response (200 OK):**
```json
{
  "token": "fixit.eyJ1c2VySWQiOiIwMWYwNjE0NS1lYWU1LTEwMmUtYjYxOS0zNjI2MGNkODY3MmYiLCJlbWFpbCI6InRlc3QyQGZpeGl0LmxrIiwicm9sZSI6ImN1c3RvbWVyIiwiZmlyc3ROYW1lIjoic2FoYW4iLCJsYXN0TmFtZSI6ImxhaGlydSIsImV4cCI6MTc1MjY0NzczOS4wfQ==.2479756acf7fb947577e7100dff0e44f932de3fbef0c659e5c2b537c11a7c451",
  "user": {
    "id": "01f06145-eae5-102e-b619-36260cd8672f",
    "email": "test@fixit.lk",
    "firstName": "Sahan",
    "lastName": "Lahiru",
    "phoneNumber": "0765820661",
    "role": "customer",
    "password": "",
    "emailVerified": false,
    "profileImageUrl": null,
    "createdAt": "2025-07-15T06:35:37.962497300Z",
    "updatedAt": "2025-07-15T06:35:37.962497300Z",
    "lastLoginAt": null
  },
  "message": "User registered successfully"
}
```

**Error Responses:**
```json
// 400 - Invalid request
{
  "message": "Email, password, firstName, and lastName are required",
  "statusCode": 400
}

// 409 - User already exists
{
  "message": "User with this email already exists",
  "statusCode": 409
}
```

### 2. User Login
**Endpoint:** `POST /api/auth/login`

**Request Body:**
```json
{
  "email": "test@fixit.lk",
  "password": "securepassword123"
}
```

**Response (200 OK):** Same format as registration response

**Error Responses:**
```json
// 401 - Invalid credentials
{
  "message": "Invalid email or password",
  "statusCode": 401
}

// 404 - User not found
{
  "message": "User not found",
  "statusCode": 404
}
```

### 3. Get User Profile
**Endpoint:** `GET /api/auth/profile`

**Headers:**
```
Authorization: Bearer fixit.eyJ1c2VySWQi...
Content-Type: application/json
```

**Response (200 OK):**
```json
{
  "id": "01f06145-eae5-102e-b619-36260cd8672f",
  "email": "test@fixit.lk",
  "firstName": "Sahan",
  "lastName": "Lahiru",
  "phoneNumber": "0765820661",
  "role": "customer",
  "password": "",
  "emailVerified": false,
  "profileImageUrl": null,
  "createdAt": "2025-07-15T06:35:37.962497300Z",
  "updatedAt": "2025-07-15T06:35:37.962497300Z",
  "lastLoginAt": "2025-07-15T06:35:40.123456789Z"
}
```

### 4. Test Authentication
**Endpoint:** `GET /api/auth/test`

**Headers:**
```
Authorization: Bearer fixit.eyJ1c2VySWQi...
```

**Response (200 OK):**
```json
{
  "message": "Authentication successful",
  "user": {
    "id": "01f06145-eae5-102e-b619-36260cd8672f",
    "email": "test@fixit.lk",
    "role": "customer",
    "firstName": "Sahan",
    "lastName": "Lahiru"
  }
}
```

## Admin Endpoints

### Get All Users (Admin Only)
**Endpoint:** `GET /api/admin/users`

**Headers:**
```
Authorization: Bearer {ADMIN_TOKEN}
```

**Response (200 OK):**
```json
{
  "message": "Admin access granted",
  "adminUser": "admin@fixit.lk"
}
```

**Error Response (403 Forbidden):**
```json
{
  "message": "Forbidden: Insufficient permissions",
  "statusCode": 403
}
```

## Using Authentication in Postman

### 1. Setting Up Headers

**For any protected endpoint:**
1. Go to the **Headers** tab in Postman
2. Add a new header:
   - **Key**: `Authorization`
   - **Value**: `Bearer YOUR_JWT_TOKEN_HERE`

**Example:**
```
Key: Authorization
Value: Bearer fixit.eyJ1c2VySWQiOiIwMWYwNjE0NS1lYWU1LTEwMmUtYjYxOS0zNjI2MGNkODY3MmYiLCJlbWFpbCI6InRlc3QyQGZpeGl0LmxrIiwicm9sZSI6ImN1c3RvbWVyIiwiZmlyc3ROYW1lIjoic2FoYW4iLCJsYXN0TmFtZSI6ImxhaGlydSIsImV4cCI6MTc1MjY0NzczOS4wfQ==.2479756acf7fb947577e7100dff0e44f932de3fbef0c659e5c2b537c11a7c451
```

### 2. Postman Environment Setup

Create an environment variable for easier token management:

1. **Create Environment**: Click the gear icon → Add
2. **Add Variable**: 
   - **Variable**: `jwt_token`
   - **Initial Value**: `your_token_here`
   - **Current Value**: `your_token_here`
3. **Use in Headers**: `Bearer {{jwt_token}}`

### 3. Auto-Extract Token from Login

Add this to the **Tests** tab of your login request:
```javascript
if (pm.response.code === 200) {
    const responseJson = pm.response.json();
    pm.environment.set("jwt_token", responseJson.token);
    console.log("Token saved to environment:", responseJson.token);
}
```

## Using Authentication Middleware in Code

### 1. Basic Authentication
```ballerina
// In your service endpoint
resource function get protectedEndpoint(http:Caller caller, http:Request req) returns error? {
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

    // User is authenticated - proceed with endpoint logic
    json successResponse = {
        "message": "Access granted",
        "userId": user.id,
        "userEmail": user.email
    };
    
    http:Response response = new;
    response.statusCode = 200;
    response.setJsonPayload(successResponse);
    check caller->respond(response);
}
```

### 2. Role-Based Authorization
```ballerina
// Allow only admins
resource function get adminOnly(http:Caller caller, http:Request req) returns error? {
    auth:User|error user = auth:authorizeRole(req, ["admin"]);
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

    // Admin access granted
}

// Allow providers and admins
resource function get providerOrAdmin(http:Caller caller, http:Request req) returns error? {
    auth:User|error user = auth:authorizeRole(req, ["provider", "admin"]);
    // ... handle response
}
```

### 3. Extract User ID Helper
```ballerina
// Get just the user ID from token
function extractUserIdFromToken(http:Request req) returns string|error {
    auth:User|error user = auth:authenticateRequest(req);
    if user is error {
        return user;
    }
    return user.id;
}
```

## JWT Token Format

The system uses a custom JWT-like token format:
- **Format**: `fixit.{base64payload}.{signature}`
- **Payload contains**: userId, email, role, firstName, lastName, expiration timestamp
- **Signature**: SHA-256 hash for verification using configured secret key
- **Expiration**: 24 hours by default (86400 seconds)

**Example decoded payload:**
```json
{
  "userId": "01f06145-eae5-102e-b619-36260cd8672f",
  "email": "test@fixit.lk",
  "role": "customer",
  "firstName": "Sahan",
  "lastName": "Lahiru",
  "exp": 1752647739.0
}
```

## Firestore Data Structure

### Users Collection
**Document ID**: Email-based identifier (special characters replaced with underscores)
**Document Path**: `/users/{email_based_id}`

```json
{
  "id": "01f06145-eae5-102e-b619-36260cd8672f",
  "email": "test@fixit.lk",
  "firstName": "Sahan",
  "lastName": "Lahiru",
  "phoneNumber": "0765820661",
  "role": "customer",
  "password": "hashed_sha256_password",
  "emailVerified": false,
  "profileImageUrl": null,
  "createdAt": "2025-07-15T06:35:37.962497300Z",
  "updatedAt": "2025-07-15T06:35:37.962497300Z",
  "lastLoginAt": "2025-07-15T06:35:40.123456789Z"
}
```

## Service Architecture

### Port Allocation
- **8080**: Authentication service (`/api/auth`)
- **8081**: Admin service (`/api/admin`)
- **8082**: AI service (`/api/ai`)
- **8083**: Health check service (`/api`)

### CORS Configuration
All services support:
- **Origins**: `*` (all origins)
- **Headers**: `Authorization`, `Content-Type`, `ngrok-skip-browser-warning`
- **Methods**: `GET`, `POST`, `PUT`, `DELETE`, `OPTIONS`, `HEAD`

## Testing with cURL

### 1. Register a new user
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@fixit.lk",
    "password": "password123",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "0712345678",
    "role": "customer"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@fixit.lk",
    "password": "password123"
  }'
```

### 3. Access protected endpoint
```bash
curl -X GET http://localhost:8080/api/auth/profile \
  -H "Authorization: Bearer fixit.eyJ1c2VySWQi..."
```

### 4. Test authentication
```bash
curl -X GET http://localhost:8080/api/auth/test \
  -H "Authorization: Bearer fixit.eyJ1c2VySWQi..."
```

### 5. Admin access (requires admin role)
```bash
curl -X GET http://localhost:8081/api/admin/users \
  -H "Authorization: Bearer {ADMIN_TOKEN}"
```

## Error Handling

### Common Error Responses

**401 Unauthorized:**
```json
{
  "message": "Unauthorized: Authorization header not found",
  "statusCode": 401
}
```

**403 Forbidden:**
```json
{
  "message": "Forbidden: Insufficient permissions",
  "statusCode": 403
}
```

**400 Bad Request:**
```json
{
  "message": "Invalid request payload format",
  "statusCode": 400
}
```

**500 Internal Server Error:**
```json
{
  "message": "Failed to create user",
  "statusCode": 500
}
```

## Configuration

### Environment Variables (Config.toml)
```toml
[backend.auth]
jwtSecretKey = "your-super-secret-jwt-key-change-this-in-production"
jwtExpirationTime = 86400.0

[backend.firestore]
firestoreProjectId = "your-project-id"
firebaseApiKey = "your-api-key"
firebaseAuthDomain = "your-project.firebaseapp.com"
firebaseStorageBucket = "your-project.appspot.com"
firebaseMessagingSenderId = "123456789"
firebaseAppId = "1:123456789:web:abcdef"
firebaseMeasurementId = "G-XXXXXXXXXX"
```

### Firebase Service Account
Ensure `firebase-service-account.json` is in the project root with proper service account credentials.

## Security Considerations

1. **Password Security**: SHA-256 hashed passwords
2. **Token Expiration**: 24-hour token lifecycle
3. **Role Validation**: Strict role-based access control
4. **Firestore Security**: Service account authentication
5. **CORS Configuration**: Properly configured for frontend integration

## Troubleshooting

### Common Issues

1. **"Authorization header not found"**
   - Ensure you're sending the `Authorization` header
   - Check header format: `Bearer {token}`

2. **"Invalid token format"**
   - Token must start with `fixit.`
   - Token must have 3 parts separated by dots

3. **"Token has expired"**
   - Re-login to get a new token
   - Check system time synchronization

4. **"User not found"**
   - Verify user exists in Firestore
   - Check email format in token payload

5. **"Insufficient permissions"**
   - Verify user role matches required roles
   - Check role assignment during