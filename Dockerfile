# Stage 1: Build the application with all dependencies
FROM php:8.2-fpm AS build

# Install system dependencies and PHP extensions for Laravel
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    libjpeg62-turbo-dev && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd && \
    docker-php-ext-enable pdo_mysql pdo_pgsql

# Install Node.js (using NodeSource repository)
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory to the app directory (same directory where Dockerfile exists)
WORKDIR /app

# Copy the Laravel application files into the container
COPY . /app

# Install PHP dependencies using Composer
RUN composer install --no-dev --optimize-autoloader

# Install Node.js dependencies and run the dev build
RUN npm install && npm run dev

# Stage 2: Production image (much smaller)
FROM php:8.2-fpm

# Install only necessary dependencies for running the application
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libpng-dev \
    libpq-dev \
    libjpeg62-turbo-dev && \
    docker-php-ext-install \
        pdo_mysql \
        pdo_pgsql \
        zip \
        gd && \
    docker-php-ext-enable pdo_mysql pdo_pgsql

# Set the working directory
WORKDIR /app

# Copy the built application from the build stage
COPY --from=build /app /app

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app

# Expose port 9001
EXPOSE 9001

# Start the PHP built-in server
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
