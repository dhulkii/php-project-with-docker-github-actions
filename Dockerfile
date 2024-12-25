# Stage 1: Build stage for PHP dependencies and Node.js assets
FROM php:8.2-fpm AS build

# Install system dependencies for Laravel
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Node.js (using NodeSource repository)
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Set working directory for the build
WORKDIR /app

# Copy application files
COPY . /app

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Install Node.js dependencies and build frontend assets
RUN npm install && npm run dev

# Stage 2: Runtime stage with Alpine
FROM php:8.2-fpm-alpine

# Install only runtime dependencies
RUN apk add --no-cache \
    libpq \
    libpng \
    libzip

# Copy compiled extensions from the build stage
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Set working directory
WORKDIR /app

# Copy application files from the build stage
COPY --from=build /app /app

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app

# Expose port
EXPOSE 9001

# Start Laravel application
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]


