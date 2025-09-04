# Use official Python slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for some packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the app source code
COPY . .

# Expose port (Render sets $PORT automatically)
ENV PORT=10000
EXPOSE $PORT

# Run the app with Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app"]

