# Multi-stage Dockerfile for building Flutter web and serving with nginx
FROM cirrusci/flutter:latest AS build

WORKDIR /app

# Copy pubspec first for dependency caching
COPY pubspec.* ./
# Ensure the image has an up-to-date Flutter/Dart SDK compatible with the project
# (upgrade to the latest stable release inside the build image before resolving deps)
RUN set -eux; \
    if git -C /sdks/flutter remote | grep -q origin 2>/dev/null; then \
    git -C /sdks/flutter remote set-url origin https://github.com/flutter/flutter.git; \
    else \
    git -C /sdks/flutter remote add origin https://github.com/flutter/flutter.git; \
    fi; \
    git -C /sdks/flutter fetch --all --tags --prune; \
    # Checkout a specific Flutter tag that ships a Dart SDK compatible with the project
    git -C /sdks/flutter checkout -f tags/3.47.5 || git -C /sdks/flutter checkout -f 3.47.5 || true; \
    flutter --version; \
    flutter pub get

# Copy the rest of the project
COPY . .

# Install font tooling and system fonts needed for Flutter font subsetting
RUN set -eux; \
    if command -v apt-get >/dev/null 2>&1; then \
    apt-get update && apt-get install -y --no-install-recommends \
    fontconfig libfreetype6 libharfbuzz0b fonts-dejavu-core python3 python3-pip && rm -rf /var/lib/apt/lists/*; \
    pip3 install --no-cache-dir fonttools; \
    elif command -v apk >/dev/null 2>&1; then \
    apk add --no-cache fontconfig freetype harfbuzz ttf-dejavu python3 py3-pip; \
    pip3 install --no-cache-dir fonttools; \
    fi

# Build the web release
RUN flutter build web --release --no-tree-shake-icons

# Production image
FROM nginx:stable-alpine

# Replace default nginx config
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 5194
CMD ["nginx", "-g", "daemon off;"]