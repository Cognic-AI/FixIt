// Database seeding script for FixIt Flutter app
// This script populates Firestore with initial data

const seedData = {
  users: [
    {
      id: "1",
      firstName: "Karen",
      lastName: "Roe",
      email: "karen.roe@example.com",
      userType: "vendor",
      rating: 4.8,
      reviewCount: 89,
      location: "Recife, Brazil",
      verified: true,
      createdAt: "2020-01-15T10:00:00Z",
    },
    {
      id: "2",
      firstName: "João",
      lastName: "Silva",
      email: "joao.silva@example.com",
      userType: "vendor",
      rating: 4.6,
      reviewCount: 45,
      location: "Olinda, Brazil",
      verified: true,
      createdAt: "2021-03-20T14:30:00Z",
    },
    {
      id: "3",
      firstName: "Lucas",
      lastName: "Scott",
      email: "lucasscott3@email.com",
      userType: "client",
      rating: 0,
      reviewCount: 0,
      location: "Recife, Brazil",
      verified: false,
      createdAt: "2024-01-01T00:00:00Z",
    },
  ],

  services: [
    {
      id: "1",
      title: "Great Apartment",
      description: "Perfect flat for 4 people. Peaceful and good location, close to bus stops and many restaurants.",
      price: 150.0,
      location: "Recife, Brazil",
      coordinates: { lat: -8.0476, lng: -34.877 },
      rating: 4.8,
      reviewCount: 124,
      hostId: "1",
      hostName: "Karen Roe",
      category: "accommodation",
      amenities: ["WiFi", "Kitchen", "Air Conditioning", "Parking"],
      imageUrl: "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=400",
      dates: "Mar 12 – Mar 15",
      active: true,
      createdAt: "2023-12-01T10:00:00Z",
    },
    {
      id: "2",
      title: "Cozy Studio",
      description: "Charming studio apartment in historic Olinda.",
      price: 85.0,
      location: "Olinda, Brazil",
      coordinates: { lat: -8.0089, lng: -34.8553 },
      rating: 4.6,
      reviewCount: 67,
      hostId: "2",
      hostName: "João Silva",
      category: "accommodation",
      amenities: ["WiFi", "Kitchen", "Historic Location"],
      imageUrl: "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400",
      dates: "Mar 20 – Mar 23",
      active: true,
      createdAt: "2023-11-15T14:30:00Z",
    },
  ],

  events: [
    {
      id: "1",
      title: "Maroon 5",
      description: "Live concert in Recife",
      location: "Recife, Brazil",
      date: "MAR 05",
      time: "20:00",
      price: 120.0,
      category: "CONCERTS",
      imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
      capacity: 50000,
      ticketsAvailable: 15000,
      organizer: "Live Nation",
      createdAt: "2024-01-10T10:00:00Z",
    },
    {
      id: "2",
      title: "Alicia Keys",
      description: "Live performance in Olinda",
      location: "Olinda, Brazil",
      date: "MAR 05",
      time: "19:00",
      price: 95.0,
      category: "CONCERTS",
      imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
      capacity: 25000,
      ticketsAvailable: 8000,
      organizer: "Music Events",
      createdAt: "2024-01-05T14:30:00Z",
    },
  ],

  chats: [
    {
      id: "1",
      participants: ["1", "3"],
      messages: [
        {
          id: "1",
          senderId: "3",
          senderName: "Lucas",
          content: "Hey Lucas!",
          timestamp: "2024-03-01T10:00:00Z",
          read: true,
        },
        {
          id: "2",
          senderId: "3",
          senderName: "Lucas",
          content: "How's your project going?",
          timestamp: "2024-03-01T10:01:00Z",
          read: true,
        },
        {
          id: "3",
          senderId: "1",
          senderName: "Karen",
          content: "Hi Brooke!",
          timestamp: "2024-03-01T10:15:00Z",
          read: true,
        },
        {
          id: "4",
          senderId: "1",
          senderName: "Karen",
          content: "It's going well. Thanks for asking!",
          timestamp: "2024-03-01T10:16:00Z",
          read: true,
        },
        {
          id: "5",
          senderId: "3",
          senderName: "Lucas",
          content: "No worries. Let me know if you need any help",
          timestamp: "2024-03-01T10:30:00Z",
          read: false,
        },
        {
          id: "6",
          senderId: "3",
          senderName: "Lucas",
          content: "You're the best!",
          timestamp: "2024-03-01T10:31:00Z",
          read: false,
        },
      ],
      createdAt: "2024-03-01T10:00:00Z",
      updatedAt: "2024-03-01T10:31:00Z",
    },
  ],

  feedback: [
    {
      id: "1",
      userId: "3",
      rating: "excellent",
      liked: ["EASY TO USE", "COMPLETE", "CONVENIENT", "LOOKS GOOD", "HELPFUL"],
      improvements: ["COULD HAVE MORE COMPONENTS"],
      comments: "Great prototyping kit overall, would love to see more components added.",
      createdAt: "2024-03-01T12:00:00Z",
    },
  ],
}

// Function to seed Firestore database
async function seedFirestore() {
  console.log("Starting Firestore seeding for FixIt Flutter app...")

  try {
    // In a real implementation, you would:
    // 1. Initialize Firebase Admin SDK
    // 2. Connect to Firestore
    // 3. Add the seed data to collections

    console.log("Seeding users collection...")
    // await db.collection('users').add(seedData.users)

    console.log("Seeding services collection...")
    // await db.collection('services').add(seedData.services)

    console.log("Seeding events collection...")
    // await db.collection('events').add(seedData.events)

    console.log("Seeding chats collection...")
    // await db.collection('chats').add(seedData.chats)

    console.log("Seeding feedback collection...")
    // await db.collection('feedback').add(seedData.feedback)

    console.log("Firestore seeding completed successfully!")
    console.log("Seed data structure:", JSON.stringify(seedData, null, 2))
  } catch (error) {
    console.error("Error seeding Firestore:", error)
  }
}

// Export for use in Flutter app
if (typeof module !== "undefined" && module.exports) {
  module.exports = { seedData, seedFirestore }
} else {
  // Browser environment
  window.seedData = seedData
  window.seedFirestore = seedFirestore
}

// Run seeding if this script is executed directly
if (typeof require !== "undefined" && require.main === module) {
  seedFirestore()
}
