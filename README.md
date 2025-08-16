# FixIt
A one-step solution to fix everyday problems - Service offering platform connecting customers with service providers

## Overview
FixIt is a comprehensive service platform that consists of:
- **Backend**: Ballerina-based REST API with MongoDB database
- **Mobile**: Flutter app for Android
- **Features**: User authentication, service requests, real-time chat, maps integration, AI assistance

## Tech Stack
- **Backend**: Ballerina 2201.12.4, MongoDB, JWT Authentication
- **Mobile**: Flutter 3.2.0+, Dart
- **Services**: Google Maps API, AI integration with Gemini

## Prerequisites

### Backend Requirements
- [Ballerina](https://ballerina.io/downloads/) 2201.12.4 or later
- MongoDB Atlas account or local MongoDB instance
- Java 11 or later

### Mobile Requirements
- [Flutter](https://flutter.dev/docs/get-started/install) 3.2.0 or later
- [Dart](https://dart.dev/get-dart) SDK
- Android Studio / VS Code with Flutter extensions
- Android development: Android SDK

### API Keys Required
- Google Maps API Key (for mobile app)
- Gemini AI API Key (for AI features)
- MongoDB connection string

## Project Structure
```
FixIt/
├── backend/           # Ballerina backend services
│   ├── main.bal       # Main service definitions
│   ├── Config.toml    # Configuration file
│   └── modules/       # Modular code organization
├── mobile/            # Flutter mobile application
│   ├── lib/           # Dart source code
│   ├── android/       # Android platform files
│   └── assets/        # Images, fonts, etc.
├── .env.example       # An example env file to be used inside the mobile folder
└── README.md          # This file
```

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/Cognic-AI/FixIt.git
cd FixIt
```

### 2. Environment Setup

#### Create Environment Files
Create a `.env` file in the mobile directory with the required environment variables (see `.env.example` in the repository).

#### Backend Configuration
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Update `Config.toml` with your database credentials and API keys:
   ```toml
   [backend.controllers]
   jwtSecretKey = "your-jwt-secret-key"
   geminiApiKey = "your-gemini-api-key"

   [backend.utils]
   connectionString = "your-mongodb-connection-string"
   mongoHost = "your-mongo-host"
   mongoPort = 27017
   mongoUsername = "your-username"
   mongoPassword = "your-password"
   mongoAuthSource = "admin"
   ```

### 3. Backend Setup

#### Install Ballerina Dependencies
```bash
cd backend
bal build
```

#### Run Backend Services
The backend runs multiple services on different ports:
```bash
# Start all services
bal run

# Services will be available on:
# - Authentication: http://localhost:8080/api/auth
# - Health Check: http://localhost:8083/api/health
# - Admin: http://localhost:8081/api/admin
# - AI Chat: http://localhost:8082/api/ai
# - Vendor Services: http://localhost:8084/api/services
# - Requests: http://localhost:8086/api/requests
# - Subscriptions: http://localhost:8085/api/subscriptions
# - Messaging: http://localhost:8087/api/chat
```

### 4. Mobile App Setup

#### Install Flutter Dependencies
```bash
cd mobile
flutter pub get
```

#### Configure Environment Variables
Create a `.env` file in the `mobile/` directory with your API keys and service URLs (see example below).

#### Run the Mobile App
Note: You may need to connect your android mobile phone and enable developer options. You also need to connect your local computer to the relevant mobile hotspot.
```bash
# For development with logs (Windows)
run_with_logs.bat

# Or manually
flutter run

# For specific platforms
flutter run -d android
```

## Environment Variables

### Mobile App (.env)
Create a `.env` file in the `mobile/` directory:

```env
# API Service URLs (Backend Services)
AUTH_SERVICE_URL=http://localhost:8080/api/auth
VENDOR_SERVICE_URL=http://localhost:8084/api/services
REQUEST_SERVICE_URL=http://localhost:8086/api/requests
SUBSCRIPTION_SERVICE_URL=http://localhost:8085/api/subscriptions
MESSAGING_SERVICE_URL=http://localhost:8087/api/chat
AI_URL=http://localhost:8082/api/ai

# Google Maps Integration
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```
> **Note**: Open Command Prompt (cmd) and enter ipconfig to find your ipv4 address. Use this address intead of 'localhost' in the above service urls

> **Note**: See `.env.example` for a complete template with all available environment variables.

## API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile
- `PUT /api/auth/changePassword` - Change password

### Service Endpoints
- `GET /api/health` - Health check
- Various service-specific endpoints on ports 8081-8087

For detailed API documentation, see `backend/AUTH_GUIDE.md`.

## Development

### Backend Development
```bash
cd backend

# Build the project
bal build

# Run with hot reload during development
bal run

# Run tests
bal test
```

### Mobile Development
```bash
cd mobile

# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build for release
flutter build apk          # Android

# Run tests
flutter test
```

### Code Structure

#### Backend (Ballerina)
- `main.bal` - Service definitions and routing
- `modules/controllers/` - Request handlers
- `modules/models/` - Data models
- `modules/utils/` - Utility functions and database config

#### Mobile (Flutter)
- `lib/main.dart` - App entry point
- `lib/pages/` - UI screens
- `lib/services/` - API and business logic services
- `lib/models/` - Data models
- `lib/widgets/` - Reusable UI components

## Database Setup

### MongoDB Atlas (Recommended)
1. Create a MongoDB Atlas account
2. Create a new cluster
3. Create a database user
4. Add your IP to the whitelist
5. Get the connection string
6. Update `backend/Config.toml` with your credentials

### Local MongoDB
```bash
# Install MongoDB locally
# Update Config.toml with local connection details
connectionString = "mongodb://localhost:27017/fixit"
```

## API Keys Setup

### Google Maps API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Maps SDK for Android/iOS
4. Create API credentials
5. Add the API key to your `.env` file

### Gemini AI API
1. Go to [Google AI Studio](https://makersuite.google.com/)
2. Generate an API key
3. Add to `backend/Config.toml`

## Troubleshooting

### Common Issues

#### Backend
- **Port conflicts**: Ensure ports 8080-8087 are available
- **MongoDB connection**: Verify connection string and network access
- **Ballerina version**: Use Ballerina 2201.12.4 or compatible version

#### Mobile
- **Environment variables**: Ensure `.env` file exists and is properly formatted
- **Flutter version**: Use Flutter 3.2.0 or later
- **API connectivity**: Verify backend services are running before starting mobile app
- **Google Maps**: Ensure API key is valid and Maps SDK is enabled

#### Development Tips
```bash
# Check Flutter doctor for setup issues
flutter doctor

# Clear Flutter cache if needed
flutter clean
flutter pub get

# Verify Ballerina installation
bal version

# Check service health
curl http://localhost:8083/api/health
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in this repository
- Check the `backend/AUTH_GUIDE.md` for authentication details
- Review the troubleshooting section above

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Ballerina API  │
│   (Mobile)      │◄──►│   (Backend)     │
└─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   MongoDB       │
                       │   (Database)    │
                       └─────────────────┘
```

The application follows a client-server architecture with the Flutter mobile app communicating with the Ballerina backend services through REST APIs. The backend handles authentication, data persistence, and business logic, while the mobile app provides the user interface and client-side functionality.
