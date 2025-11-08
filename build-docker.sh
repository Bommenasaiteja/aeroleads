#!/bin/bash
set -e

echo "=========================================="
echo "Building Autodialer Docker Image"
echo "=========================================="

# Enable BuildKit for faster builds with better caching
export DOCKER_BUILDKIT=1

# Build the image
echo "Starting build..."
docker build \
  -t autodialer:latest \
  -f Dockerfile \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --progress=plain \
  .

echo ""
echo "=========================================="
echo "Build Complete!"
echo "=========================================="
echo ""
echo "Image built successfully: autodialer:latest"
echo ""
echo "To run the container:"
echo "  docker-compose up"
echo ""
echo "Or run directly:"
echo "  docker run -p 3000:3000 -e SECRET_KEY_BASE=your_secret autodialer:latest"
echo ""
