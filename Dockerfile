FROM php:8.1-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libldap2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql

# MySQLi compatibility
RUN echo "mysqli.report_mode=0" \
    > /usr/local/etc/php/conf.d/mysqli-compat.ini

# Apache configuration
RUN a2enmod rewrite

# TestLink directories
RUN mkdir -p /var/testlink/logs \
    /var/testlink/upload_area \
    && chown -R www-data:www-data /var/testlink \
    && chmod -R 775 /var/testlink

WORKDIR /var/www/html

# Download TestLink
RUN git clone --depth 1 \
    --branch testlink_1_9_20_fixed \
    https://github.com/TestLinkOpenSourceTRMS/testlink-code.git temp \
    && cp -a temp/. . \
    && rm -rf temp

# Patch installer for managed MySQL databases
RUN cat > /tmp/patch.php <<'PHP'
<?php

$file = '/var/www/html/install/installNewDB.php';

$code = file_get_contents($file);

$start = strpos(
    $code,
    "$user_host = explode('@',$tl_db_login);"
);

$end = strpos(
    $code,
    "// Schema Operations (CREATE, ALTER, ecc).",
    $start
);

if ($start === false || $end === false) {
    fwrite(STDERR, "ERROR: TestLink installer patch location not found.\n");
    exit(1);
}

$replacement = <<<'CODE'
$user_host = explode('@', $tl_db_login);

if ($db_type == 'mysql') {
    echo "<br /><b>Using existing MySQL user `"
       . htmlspecialchars($user_host[0])
       . "`:</b><span class='ok'>OK!</span>";
} else {
    $msg = create_user_for_db(
        $dbDriverName,
        $db_name,
        $db_server,
        $db_admin_name,
        $db_admin_pass,
        $tl_db_login,
        $tl_db_passwd
    );

    echo "<br /><b>Creating Testlink DB user `"
       . htmlspecialchars($user_host[0])
       . "`:</b>";

    if (strpos($msg, 'ok -') === FALSE) {
        echo "<span class='notok'>Failed!</span>";
        $errors += 1;
    } else {
        echo "<span class='ok'>OK! ($msg)</span>";
    }
}

// ------------------------------------------------------------------------
// Schema Operations (CREATE, ALTER, ecc).
CODE;

$code = substr_replace(
    $code,
    $replacement,
    $start,
    $end - $start + strlen("// Schema Operations (CREATE, ALTER, ecc).")
);

if (file_put_contents($file, $code) === false) {
    fwrite(STDERR, "ERROR: Could not write installer patch.\n");
    exit(1);
}

echo "TestLink MySQL installer patch applied successfully.\n";
PHP

RUN php /tmp/patch.php \
    && rm /tmp/patch.php

# Permissions
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
