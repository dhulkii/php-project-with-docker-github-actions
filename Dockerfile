# Build stage
FROM node:18-alpine AS build

# Set working directory
WORKDIR /app

# Copy only package.json and package-lock.json to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies and build assets
RUN npm install && npm run build

# Application stage
FROM php:8.2-fpm-alpine

# Install required runtime dependencies
RUN apk add --no-cache \
    libpq \
    libpng \
    libzip \
    && docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd

# Set working directory
WORKDIR /app

# Copy application code
COPY . /app

# Copy built assets from the build stage
COPY --from=build /app/public /app/public

# Install PHP dependencies with composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer install --no-dev --optimize-autoloader

# Set appropriate permissions
RUN chown -R www-data:www-data /app

# Expose the application port
EXPOSE 9001

# Start Laravel application
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
