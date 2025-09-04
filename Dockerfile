# Use official slim Python image
FROM python:3.9-slim

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose port (Render uses $PORT)
EXPOSE 5000

# Run Flask app via Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "WebApp:app"]
