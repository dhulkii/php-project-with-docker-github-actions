# Stage 1: Build stage for PHP dependencies and Node.js assets
FROM php:8.2-fpm-alpine AS build

# Install build dependencies for PHP extensions and Node.js
RUN apk add --no-cache --virtual .build-deps \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    build-base \
    nodejs \
    npm && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory for the build
WORKDIR /app

# Copy application files
COPY . /app

# Install PHP dependencies (production only) and optimize autoloader
RUN composer install --no-dev --optimize-autoloader --no-scripts --prefer-dist

# Install Node.js dependencies (production only) and build frontend assets
RUN npm install --production && npm run prod

# Clean up unnecessary build dependencies and caches to reduce size
RUN apk del .build-deps && \
    rm -rf /root/.composer/cache /root/.npm /app/node_modules /app/resources/js /app/resources/css

# Stage 2: Runtime stage
FROM php:8.2-fpm-alpine

# Install only runtime dependencies
RUN apk add --no-cache \
    libpq \
    libpng \
    libzip \
    nodejs \
    npm

# Set working directory
WORKDIR /app

# Copy PHP runtime extensions and configuration from the build stage
COPY --from=build /usr/local/lib/php/extensions /usr/local/lib/php/extensions
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d

# Copy application files from the build stage (excluding unnecessary ones)
COPY --from=build /app /app

# Remove unnecessary files from the application directory
RUN rm -rf /app/.git /app/tests /app/node_modules /app/resources/js /app/resources/css

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app

# Expose port
EXPOSE 9001

# Start Laravel application
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
