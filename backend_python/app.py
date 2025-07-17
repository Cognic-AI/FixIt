from fastapi import FastAPI, HTTPException, Query
from motor.motor_asyncio import AsyncIOMotorClient
from pydantic import BaseModel
from typing import List
import os

app = FastAPI()

# Load from env or config file
MONGO_URI = os.getenv("connectionString", "mongodb://localhost:27017")
client = AsyncIOMotorClient(MONGO_URI)
db = client['main']

class Vendor(BaseModel):
    id: str
    firstName: str
    lastName: str
    category: str
    location: dict  # GeoJSON Point
    role: str

@app.get("/health")
async def health_check():
    try:
        # Try to ping the database
        await client.admin.command('ping')
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Database connection failed: {str(e)}")

@app.get("/vendors/nearest", response_model=List[Vendor])
async def get_nearest_vendors(
    lat: float = Query(...),
    lng: float = Query(...),
    category: str = Query(...),
    maxDistance: int = Query(5000)
):
    cursor = db.users.find({
        "role": "vendor",
        "category": category,
        "location": {
            "$near": {
                "$geometry": {"type": "Point", "coordinates": [lng, lat]},
                "$maxDistance": maxDistance
            }
        }
    })

    results = []
    async for vendor in cursor:
        results.append(Vendor(**vendor))
    return results

@app.get("/clients/{client_id}/location")
async def get_client_location(client_id: str):
    print(f"Looking for client with ID: {client_id}")
    client_doc = await db.users.find_one({"id": client_id})
    print("Client document retrieved:", client_doc)
    if not client_doc:
        print("Client not found!")
        raise HTTPException(status_code=404, detail="Client not found")
    print("Client found:", client_doc)
    return {"location": client_doc["location"]}
