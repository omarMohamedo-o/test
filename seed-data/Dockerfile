# Lightweight Dockerfile for Seed Data service
FROM python:3.11-alpine

# Install apache-bench for load testing and bash for scripts
RUN apk add --no-cache apache2-utils bash curl

# Create non-root user
RUN addgroup -S appuser && adduser -S appuser -G appuser

# Set working directory
WORKDIR /app

# Copy seed data scripts
COPY --chown=appuser:appuser . .

# Make scripts executable and generate POST data files as root
RUN chmod +x generate-votes.sh && \
    python make-data.py && \
    chown appuser:appuser posta postb

# Switch to non-root user
USER appuser

# Run the seed data generation script
CMD ["./generate-votes.sh"]
