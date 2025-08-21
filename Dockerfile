# Use official PHP FPM image as base
FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gnupg2 \
    apt-transport-https \
    curl \
    nginx \
    unzip \
    zip \
    git \
    libzip-dev \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    libgssapi-krb5-2 \
    lsb-release \
    ca-certificates \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxpm-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd zip intl pdo

# Add Microsoft repository and install ODBC + tools
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg \
    && echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y \
        msodbcsql18 \
        mssql-tools18 \
        unixodbc-dev \
        gcc \
        g++ \
        make \
        autoconf \
        libc-dev \
        pkg-config \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin:$PATH"' >> /etc/profile.d/mssql-tools.sh \
    && chmod +x /etc/profile.d/mssql-tools.sh \
    && ln -s /opt/mssql-tools18/bin/* /usr/local/bin/

# Install SQLSRV & PDO_SQLSRV via PECL
RUN pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy project files into the container
WORKDIR /var/www/html
COPY . /var/www/html

# Copy Nginx config and start script
COPY default.conf /etc/nginx/conf.d/default.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Set correct permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose default HTTP port
EXPOSE 80

# Start both PHP-FPM and Nginx
CMD ["/start.sh"]
