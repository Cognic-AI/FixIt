import ballerina/random;

// Generates a random alphanumeric ID of specified length
public isolated function generateAlphanumericId(int length = 16) returns string|error {
    string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    string id = "";
    int i = 0;

    while i < length {
        // Generate random index between 0 and chars.length()-1
        int randomInt = check random:createIntInRange(0, 255);
        int:Unsigned8 randomByte = <int:Unsigned8>randomInt;
        int index = randomByte % chars.length();

        // Get character at random position
        string char = chars.substring(index, index + 1);
        id += char;
        i += 1;
    }

    return id;
}
