# Stage 1: Build dependencies
FROM python:3.9-slim AS requirements-stage

# Set working directory
WORKDIR /tmp

# Install necessary system libraries
RUN apt-get update && apt-get install -y gcc libffi-dev libssl-dev && apt-get clean

# Install Poetry
RUN pip install "poetry==1.5.1"

# Copy dependency files
COPY ./pyproject.toml /tmp/pyproject.toml
COPY ./poetry.lock /tmp/poetry.lock

# Install dependencies and export requirements
RUN poetry install --no-dev
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# Stage 2: Application runtime
FROM python:3.11-slim-bookworm

# Set working directory
WORKDIR /app

# Copy exported requirements from the first stage
COPY --from=requirements-stage /tmp/requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# Install Playwright dependencies
RUN playwright install-deps && \
    playwright install

# Install additional system utilities
RUN apt-get update && apt-get install -y \
    xauth x11-apps netpbm && \
    apt-get clean

# Copy application files
COPY . /app

# Set environment variables
ENV PYTHONPATH="/app:$PYTHONPATH"
ENV VIDEO_PATH=/data/videos
ENV HAR_PATH=/data/har
ENV LOG_PATH=/data/log
ENV ARTIFACT_STORAGE_PATH=/data/artifacts

# Copy and make the entrypoint script executable
COPY ./entrypoint-skyvern.sh /app/entrypoint-skyvern.sh
RUN chmod +x /app/entrypoint-skyvern.sh

# Set the default command to run the entrypoint script
CMD ["/bin/bash", "/app/entrypoint-skyvern.sh"]
