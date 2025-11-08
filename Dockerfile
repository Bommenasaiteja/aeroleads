# Multi-stage Dockerfile for Autodialer - Optimized for Speed and Size

# Stage 1: Build Stage (includes build dependencies)
FROM ruby:3.1.4-slim AS builder

WORKDIR /rails

# Install build dependencies and runtime dependencies in one layer
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libpq-dev \
    libsqlite3-dev \
    libvips \
    pkg-config \
    curl \
    nodejs \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy only dependency files first for better layer caching
COPY ["autodialer & blogs(Task2 & Task3)/Gemfile", "autodialer & blogs(Task2 & Task3)/Gemfile.lock", "./"]

# Install gems with jobs flag for parallel installation (faster)
# Skip documentation to save time and space
# Note: Not using deployment mode to allow Gemfile.lock updates during build
RUN bundle config set --local without 'development test' && \
    bundle config set --local jobs 4 && \
    bundle config set --local no-cache 'true' && \
    bundle install --no-binstubs --retry 3 && \
    bundle clean --force && \
    rm -rf /usr/local/bundle/cache/*.gem && \
    find /usr/local/bundle/gems/ -name "*.c" -delete && \
    find /usr/local/bundle/gems/ -name "*.o" -delete

# Copy the rest of the application
COPY ["autodialer & blogs(Task2 & Task3)", "/rails/"]

# Precompile assets (set all required env vars to avoid errors)
RUN SECRET_KEY_BASE=dummy \
    RAILS_ENV=production \
    bundle exec rails assets:precompile 2>/dev/null || echo "Asset precompilation skipped"

# Stage 2: Runtime Stage (minimal image)
FROM ruby:3.1.4-slim AS runtime

WORKDIR /rails

# Install only runtime dependencies (no build tools)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libpq5 \
    libsqlite3-0 \
    libvips \
    curl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy installed gems from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application from builder
COPY --from=builder /rails /rails

# Create non-root user for security
RUN useradd -m -u 1000 rails && \
    mkdir -p /rails/tmp /rails/log /rails/storage && \
    chown -R rails:rails /rails

USER rails

# Expose port (Railway sets PORT=8080, but we'll use env var for flexibility)
EXPOSE 3000
ENV PORT=3000

# Health check (use PORT env var)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:${PORT:-3000}/up || exit 1

# Start server with production settings
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# Create entrypoint script to handle database setup
COPY --chown=rails:rails <<-"EOF" /rails/docker-entrypoint.sh
#!/bin/sh
set -e

echo "Preparing database..."
bundle exec rails db:prepare

echo "Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0
EOF

RUN chmod +x /rails/docker-entrypoint.sh

CMD ["/bin/sh", "/rails/docker-entrypoint.sh"]
