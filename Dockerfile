FROM php:8.2-fpm

# Install system dependencies and PHP extensions for Laravel
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
        gd && \
    docker-php-ext-enable pdo_mysql pdo_pgsql

# Install Node.js (using NodeSource repository)
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer --version  # Add this to check if Composer installed correctly

# Set working directory to the app directory (same directory where Dockerfile exists)
WORKDIR /app

# Copy the Laravel application files into the container
COPY . /app

# Ensure .env file is copied
COPY .env /app/.env  # Make sure this line is present to copy the .env file

# Install PHP dependencies using Composer
RUN composer install --no-dev --no-interaction --optimize-autoloader  # Install dependencies

# Set appropriate permissions for Laravel folders
RUN chown -R www-data:www-data /app

# Install Node.js dependencies and run the dev build
RUN npm install && npm run dev

# Expose port 9001
EXPOSE 9001

# Start the PHP built-in server
CMD ["sh", "-c", "php artisan key:generate && php artisan migrate && php artisan db:seed && php artisan serve --host=0.0.0.0 --port=9001"]
