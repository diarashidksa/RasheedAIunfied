# Base image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy requirements first for caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt -f https://download.pytorch.org/whl/cpu

# Copy app code
COPY . .

# Expose the port your app runs on
EXPOSE 8000

# Start the app with Gunicorn
CMD ["gunicorn", "-w", "1", "-b", "0.0.0.0:8000", "WebApp:app"]

