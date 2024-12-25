# First stage: Build stage (with necessary dependencies)
FROM php:8.2-fpm-alpine AS build

# Install system dependencies and PHP extensions for Laravel
RUN apk add --no-cache \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    nodejs \
    npm && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd && \
    docker-php-ext-enable pdo_mysql pdo_pgsql

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory to the app directory
WORKDIR /app

# Copy the Laravel application files into the container
COPY . /app

# Install PHP dependencies using Composer (with --no-dev to skip dev dependencies)
RUN composer install --no-dev

# Install Node.js dependencies and run the dev build
RUN npm install && npm run dev

# Clean up build dependencies to reduce image size
RUN apk del git unzip curl libzip-dev libpng-dev libpq-dev nodejs npm && \
    rm -rf /var/cache/apk/* /tmp/* /app/node_modules

# Second stage: Final runtime image
FROM php:8.2-fpm-alpine AS runtime

# Install only the necessary runtime dependencies (no build tools)
RUN apk add --no-cache \
    libpng-dev \
    libpq-dev \
    postgresql-client

# Copy only the necessary files from the build stage
COPY --from=build /app /app

# Set the working directory
WORKDIR /app

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app

# Expose port 9001
EXPOSE 9001

# Start the PHP built-in server
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
