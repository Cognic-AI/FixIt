import ballerinax/mongodb;

// MongoDB configuration
configurable string connectionString = ?;
configurable string mongoHost = ?;
configurable int mongoPort = 27017;
configurable string mongoUsername = ?;
configurable string mongoPassword = ?;
configurable string mongoAuthSource = "admin"; // Default admin database for authentication

public final mongodb:Client mongoDb = check new ({
    connection: connectionString
});