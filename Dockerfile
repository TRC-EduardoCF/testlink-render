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
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql

RUN echo "mysqli.report_mode=0" \
    > /usr/local/etc/php/conf.d/mysqli-compat.ini

RUN a2enmod rewrite

RUN mkdir -p /var/testlink/logs \
    /var/testlink/upload_area \
    && chown -R www-data:www-data /var/testlink \
    && chmod -R 775 /var/testlink

WORKDIR /var/www/html

RUN git clone --depth 1 \
    --branch testlink_1_9_20_fixed \
    https://github.com/TestLinkOpenSourceTRMS/testlink-code.git temp \
    && cp -a temp/. . \
    && rm -rf temp

# Adaptar instalador para Clever Cloud
RUN python3 - <<'PY'
from pathlib import Path

p = Path("/var/www/html/install/installNewDB.php")
s = p.read_text()

start = s.find("$user_host = explode(")
end = s.find("// Schema Operations", start)

if start < 0 or end < 0:
    raise SystemExit("No se ha podido adaptar el instalador")

replacement = """
$user_host = explode('@', $tl_db_login);

if ($db_type == 'mysql') {
    echo "<br /><b>Using existing MySQL user:</b>";
    echo "<span class='ok'>OK!</span>";
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

    echo "<br /><b>Creating Testlink DB user:</b>";

    if (strpos($msg, 'ok -') === FALSE) {
        echo "<span class='notok'>Failed!</span>";
        $errors += 1;
    } else {
        echo "<span class='ok'>OK! ($msg)</span>";
    }
}

"""

p.write_text(s[:start] + replacement + s[end:])
print("Instalador adaptado correctamente")
PY

RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
