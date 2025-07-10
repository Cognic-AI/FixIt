# FixIt Backend API

A Ballerina-based backend service for the FixIt mobile application with Firebase Firestore integration.

## Features

- **Authentication**: User registration and login
- **Services**: CRUD operations for service listings
- **Events**: Event management and listings
- **Chat**: Real-time messaging system
- **Bookings**: Service booking management
- **Reviews**: User review system
- **Feedback**: User feedback collection
- **Database Seeding**: Development endpoint to populate Firestore

## Prerequisites

- Ballerina Swan Lake 2201.8.5 or later
- Firebase project with Firestore enabled
- Firebase service account credentials

## Setup

1. **Install Ballerina**
   \`\`\`bash
   # Download from https://ballerina.io/downloads/
   \`\`\`

2. **Firebase Setup**
   - Create a Firebase project at https://console.firebase.google.com/
   - Enable Firestore Database
   - Create a service account and download the JSON key
   - Update `Config.toml` with your Firebase credentials

3. **Configuration**
   \`\`\`bash
   # Copy the example config
   cp Config.toml.example Config.toml
   
   # Update with your Firebase credentials
   nano Config.toml
   \`\`\`

4. **Install Dependencies**
   \`\`\`bash
   bal pull
   \`\`\`

## Running the Server

\`\`\`bash
# Development mode
bal run

# Production mode
bal build
bal run target/bin/backend.jar
\`\`\`

The server will start on `http://localhost:8080`

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Services
- `GET /api/services` - List services (with filters)
- `POST /api/services` - Create new service

### Events
- `GET /api/events` - List events (with filters)

### Chat
- `GET /api/chats/{userId}` - Get user's chats
- `GET /api/chats/{chatId}/messages` - Get chat messages
- `POST /api/chats/{chatId}/messages` - Send message

### Bookings
- `GET /api/bookings/{userId}` - Get user's bookings
- `POST /api/bookings` - Create booking

### Reviews
- `GET /api/reviews/service/{serviceId}` - Get service reviews
- `POST /api/reviews` - Create review

### Feedback
- `POST /api/feedback` - Submit feedback

### Development
- `POST /api/seed` - Seed database (development only)
- `GET /api/health` - Health check

## Database Schema

The application uses Firebase Firestore with the following collections:

- `users` - User profiles
- `services` - Service listings
- `events` - Event listings
- `chats` - Chat conversations
- `messages` - Chat messages
- `bookings` - Service bookings
- `reviews` - User reviews
- `feedback` - User feedback

## Development

### Seeding Database

Use the seed endpoint to populate Firestore with sample data:

\`\`\`bash
curl -X POST http://localhost:8080/api/seed
\`\`\`

This will clear existing data and populate the database with sample users, services, events, chats, and other data.

### CORS Configuration

CORS is enabled for all origins in development. Update the CORS configuration in `main.bal` for production use.

## Deployment

1. **Build the application**
   \`\`\`bash
   bal build
   \`\`\`

2. **Deploy to your preferred platform**
   - Docker
   - Kubernetes
   - Cloud platforms (AWS, GCP, Azure)

## Environment Variables

Set these environment variables for production:

- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`
- `SERVER_PORT` (default: 8080)

## Security Notes

- Store Firebase credentials securely
- Use environment variables in production
- Implement proper authentication middleware
- Add rate limiting for production use
- Validate all input data
- Use HTTPS in production

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.
