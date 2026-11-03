
FROM php:8.1-apache

# Dependencias
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    python3 \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libldap2-dev \
    && rm -rf /var/lib/apt/lists/*

# Extensiones PHP
RUN docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql

# Compatibilidad MySQLi
RUN echo "mysqli.report_mode=0" \
    > /usr/local/etc/php/conf.d/mysqli-compat.ini

# Apache
RUN a2enmod rewrite

# Directorios
RUN mkdir -p /var/testlink/logs \
    /var/testlink/upload_area \
    && chown -R www-data:www-data /var/testlink \
    && chmod -R 775 /var/testlink

WORKDIR /var/www/html

# Descargar TestLink
RUN git clone --depth 1 \
    --branch testlink_1_9_20_fixed \
    https://github.com/TestLinkOpenSourceTRMS/testlink-code.git temp \
    && cp -a temp/. . \
    && rm -rf temp

# Corregir instalador para Clever Cloud
RUN python3 - <<'PY'
from pathlib import Path

p = Path("/var/www/html/install/installNewDB.php")
s = p.read_text()

start = s.find("$user_host = explode(")
end = s.find("// Schema Operations", start)

if start == -1 or end == -1:
    raise SystemExit("ERROR: No se encuentra el bloque original de TestLink")

replacement = """$user_host = explode('@',$tl_db_login);

// Clever Cloud: reuse the existing database user.
// Do not attempt to create or inspect MySQL server users.
if ($db_type == 'mysql') {
    echo "<br /><b>Using existing TestLink DB user `" . $user_host[0] . "`:</b>";
    echo "<span class='ok'>OK!</span>";
} else {
    $msg = create_user_for_db($dbDriverName,$db_name, $db_server,
                              $db_admin_name, $db_admin_pass,
                              $tl_db_login, $tl_db_passwd);

    echo "<br /><b>Creating Testlink DB user `" . $user_host[0] . "`</b>:";
    if ( strpos($msg,'ok -') === FALSE ) {
        echo "<span class='notok'>Failed!</span></b> - Could not create user: $tl_db_login!";
        $errors += 1;
    }
    else {
        echo "<span class='ok'>OK! ($msg) </span>";
    }
}

"""

p.write_text(s[:start] + replacement + s[end:])

print("OK: Instalador de TestLink adaptado para Clever Cloud")
PY

# Permisos
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]

