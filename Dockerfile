# Use official Python 3.9 slim image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip

# Copy requirements
COPY requirements.txt .

# Install Python dependencies (including PyTorch CPU)
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/cpu

# Copy application code
COPY . .

# Expose port (adjust if your app uses a different one)
EXPOSE 8000

# Run Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "WebApp:app", "--workers", "1"]
