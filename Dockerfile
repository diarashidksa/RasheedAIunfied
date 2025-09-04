# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY . .

# Expose port
EXPOSE 10000

# Start Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "WebApp:app", "--workers", "1", "--threads", "4"]


