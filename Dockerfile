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

# Precompile assets (set all required env vars)
# Note: We need a valid SECRET_KEY_BASE for asset compilation
RUN SECRET_KEY_BASE='0ebf7c3d6331b3eeb3c04cda45963ac7e0a62bba7ef9537b0aac37ae2a5c982d7c9e2e7c2446f61cbc2e1b118e0746f6584ae37154d85244acac701ba346b0de' \
    RAILS_ENV=production \
    bundle exec rails assets:precompile

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

# Expose port
EXPOSE 3000

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
