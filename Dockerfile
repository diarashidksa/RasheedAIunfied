# Use official Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Upgrade pip first
RUN pip install --upgrade pip

# Install Python dependencies (PyTorch CPU, retry on failures)
RUN pip install --no-cache-dir -r requirements.txt \
    -f https://download.pytorch.org/whl/cpu \
    --retries 10 --timeout 120

# Copy application code
COPY . .

# Expose port if using Flask or FastAPI
EXPOSE 5000

# Default command to run your app
CMD ["python", "WebApp.py"]
