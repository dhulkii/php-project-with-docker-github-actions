# Stage 1: Build dependencies and assets
FROM node:18-alpine AS build
WORKDIR /app

# Copy only package.json to leverage Docker cache
COPY package.json ./

# Uncomment the next line if package-lock.json exists:
# COPY package-lock.json ./

# Install dependencies
RUN npm install

# Copy resources if they exist
COPY resources/js ./resources/js
RUN mkdir -p ./resources/css && echo "{}" > ./resources/css/placeholder.css
COPY resources/css ./resources/css

# Build assets (if applicable)
RUN npm run prod

# Stage 2: PHP Application Setup
FROM php:8.2-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    libpq libpng libzip git unzip curl && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd && \
    docker-php-ext-enable pdo_mysql pdo_pgsql

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory to /app
WORKDIR /app

# Copy only the necessary files to the runtime image
COPY . /app

# Install PHP dependencies using Composer
RUN composer install --no-dev --optimize-autoloader

# Copy built assets from the build stage
COPY --from=build /app/public/js /app/public/js
COPY --from=build /app/public/css /app/public/css

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

# Expose port 9001
EXPOSE 9001

# Start the Laravel application
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
