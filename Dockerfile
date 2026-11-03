FROM php:8.1-apache

RUN apt-get update && apt-get install -y \
    git \
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

RUN git clone --branch testlink_1_9_20_fixed https://github.com/TestLinkOpenSourceTRMS/testlink-code.git temp \
    && cp -a temp/. . \
    && rm -rf temp

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
