# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

#Copy requirements first for caching
COPY requirements.txt .

# Upgrade pip and install PyTorch CPU version first
RUN pip install --upgrade pip && \
    pip install torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu

# Install other dependencies
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Expose the port (optional, mostly for documentation)
EXPOSE 10000

# Start Gunicorn using the $PORT environment variable
CMD gunicorn --bind 0.0.0.0:$PORT WebApp:app --workers 1 --threads 4
