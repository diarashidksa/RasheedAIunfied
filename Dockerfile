# Use an official Python runtime as a parent image
# python:3.9-slim is a good choice for smaller image size
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the requirements.txt file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's source code into the container
# This is done after installing dependencies to leverage Docker's build cache
COPY . .

# Expose the port the app runs on (assuming Flask's default)
EXPOSE 5000

# Define the command to run the application
# This uses 'gunicorn' for a production-ready server, which is better than the Flask dev server
# If you don't have gunicorn, you can use: CMD ["python", "WebApp.py"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "WebApp:app"]