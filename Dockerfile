FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    wget \
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

RUN wget -O testlink.zip https://github.com/TestLinkOpenSourceTRMS/testlink-code/archive/refs/heads/main.zip \
    && unzip testlink.zip \
    && mv testlink-code-main/* . \
    && rm -rf testlink.zip testlink-code-main

EXPOSE 80

CMD ["apache2-foreground"]
