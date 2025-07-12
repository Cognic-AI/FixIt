import nalaka/firestore;

configurable string projectId = ?;

// Initialize Firestore client
firestore:Client firestoreClient = check new ({
    serviceAccountPath: "./firebase-service-account.json",
    jwtConfig: {
        scope: "https://www.googleapis.com/auth/datastore",
        expTime: 3600
    }
});

public function getFirestoreClient() returns firestore:Client {
    return firestoreClient;
}
