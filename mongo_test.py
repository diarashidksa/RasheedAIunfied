from dotenv import load_dotenv
import os
from pymongo import MongoClient

# Load environment variables from .env file
load_dotenv()
MONGO_URI = os.getenv("MONGO_URI")

if not MONGO_URI:
    print("Error: MONGO_URI is not set in the .env file.")
else:
    try:
        print("Attempting to connect to MongoDB...")
        # Use a 5-second timeout for a quicker diagnosis
        client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)

        # The ismaster command is cheap and does not require auth.
        # It forces the client to try to connect and report the result.
        client.admin.command('ismaster')

        print("\n🎉 Success! Connection to MongoDB was successful.")
        print("MongoDB version:", client.server_info()["version"])

    except Exception as e:
        print("\n❌ Failed to connect to MongoDB.")
        print("Error details:", e)
        print("\nPossible solutions:")
        print("1. Check your network (firewall/proxy).")
        print("2. Ensure your IP address is on the MongoDB Atlas access list.")
        print("3. Verify your MONGO_URI string for any typos.")
        print("4. Your pymongo or SSL libraries may be outdated. Try `pip install --upgrade pymongo`.")