FROM ballerina/ballerina:2201.8.5

# Set working directory
WORKDIR /app

# Copy Ballerina project files
COPY Ballerina.toml .
COPY Config.toml .
COPY src/ src/

# Build the application
RUN bal build

# Expose port
EXPOSE 8080

# Run the application
CMD ["bal", "run", "target/bin/backend.jar"]
