FROM php:8.1-apache

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libldap2-dev \
    && docker-php-ext-install mysqli

RUN mkdir -p /var/testlink/logs \
    && mkdir -p /var/testlink/upload_area \
    && chmod -R 777 /var/testlink

WORKDIR /var/www/html

RUN wget -O testlink.zip https://github.com/TestLinkOpenSourceTRMS/testlink-code/archive/refs/tags/1.9.20-20251208.zip \
    && unzip testlink.zip \
    && cp -a testlink-code-1.9.20-20251208/. . \
    && rm -rf testlink.zip testlink-code-1.9.20-20251208

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
