# Use official Python base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Upgrade pip
RUN pip install --upgrade pip

# Install Python dependencies (including PyTorch CPU)
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/cpu

# Copy application code
COPY . .

# Expose port (adjust to your app)
EXPOSE 8000

# Start the app with Gunicorn (adjust app module if needed)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "WebApp:app", "--workers", "2"]
