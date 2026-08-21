FROM python:3.11-slim

# Prevent Python from writing bytecode (.pyc) and enable unbuffered logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies required for compilation and Postgres drivers
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies (cached if requirements.txt doesn't change)
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy backend application source code
COPY . .

EXPOSE 8000

# Run pending Alembic migrations, then start Uvicorn. If the migration
# fails, the container exits/fails to start instead of silently serving
# stale schema — you want a loud deploy failure here, not a quiet 500
# later when a table doesn't exist.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]