FROM amazonlinux:latest

# Set some labels so the Docker image has some useful metadata.
LABEL description="Bankrate Standard PHP Base"
LABEL maintainer="Steven Crothers <steven.crothers@bankrate.com>"

# Setup some environment variables for later usage.
ENV PHP_INI_DIR "/etc/php.d"
ENV PHP_FPM_DIR "/etc/php-fpm.d"

# Set required Composer settings.
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_VERSION 1.5.2

# Set system environment variables for the container.
ENV PATH="/root/.composer/vendor/bin:${PATH}"

# Update the container fully for security.
RUN /usr/bin/yum update -y && \
    /usr/bin/yum clean all

# Install dependancies for Composer and such.
RUN /usr/bin/yum install -y \
    curl \
    git \
    subversion \
    openssh \
    openssl \
    mercurial \
    tini \
    wget \
    zlib \
    zlib-devel && \
    /usr/bin/yum clean all

# Install PHP 7.1.
RUN /usr/bin/yum install -y \
    php71 \
    php71-bcmath \
    php71-cli \
    php71-common \
    php71-dba \
    php71-embedded \
    php71-enchant \
    php71-fpm \
    php71-gd \
    php71-gmp \
    php71-imap \
    php71-intl \
    php71-json \
    php71-ldap \
    php71-mbstring \
    php71-mcrypt \
    php71-mysqlnd \
    php71-odbc \
    php71-opcache \
    php71-pdo \
    php71-pdo-dblib \
    php71-pecl-oauth \
    php71-pecl-redis \
    php71-pecl-ssh2 \
    php71-pgsql \
    php71-process \
    php71-recode \
    php71-snmp \
    php71-xml \
    php71-xmlrpc && \
    /usr/bin/yum clean all

# Setup a PHP memory limit and timezone for Composer.
RUN echo "memory_limit=-1" > "$PHP_INI_DIR/memory-limit.ini" && \
    echo "date.timezone=UTC" > "$PHP_INI_DIR/date_timezone.ini"

# Install Composer on the system.
RUN /usr/bin/curl -o /usr/local/bin/composer \
    "https://getcomposer.org/download/$COMPOSER_VERSION/composer.phar" && \
    /bin/chmod 755 /usr/local/bin/composer

# Globally install PHP Unit for testing purposes.
RUN /usr/local/bin/composer global require phpunit/phpunit

# Create the app directory to install our code into and set as working directory.
RUN /bin/mkdir /app
WORKDIR /app

# Add our environment files for the container.
ADD files/bash_profile /root/.bash_profile
ADD files/bashrc /root/.bashrc
ADD files/prompt.sh /etc/profile.d/prompt.sh

# Install confd for configuration creation.
RUN /usr/bin/curl -L -o /usr/local/bin/confd \
    "https://github.com/kelseyhightower/confd/releases/download/v0.14.0/confd-0.14.0-linux-amd64" && \
    /bin/chmod 755 /usr/local/bin/confd && \
    /bin/mkdir /etc/confd

# Install the confd configuration file.
ADD files/confd.toml /etc/confd/confd.toml

# Install supervisord for process management.
RUN /usr/bin/yum install -y python27-pip && \
    /usr/bin/yum clean all && \
    /usr/bin/easy_install supervisor

# Install Nginx for the web frontend.
RUN /usr/bin/yum install -y nginx && \
    /usr/bin/yum clean all

# Default configuration settings.
ENV APP_USER "app"
ENV APP_GROUP "app"
ENV NGINX_WEB_PORT 8080
ENV NGINX_WEB_ROOT "/app"
ENV PHP_MAX_PROCS 2
ENV PHP_FPM_PORT 9000
ENV PHP_SECRET_KEY "cfc05035528bde5c6aabe7a8a7945715"

# Create the app system user for the container.
RUN /usr/sbin/useradd \
    --comment "Application User" \
    --home-dir /app \
    --no-create-home \
    --system \
    --shell /sbin/nologin \
    app

# Install configuration files.
RUN /bin/mkdir /etc/confd/templates && \
    /bin/mkdir /etc/confd/conf.d && \
    /bin/mkdir /var/log/supervisor && \
    /bin/chown app:app /var/log/supervisor
ADD configs/templates/nginx.toml /etc/confd/conf.d/nginx.toml
ADD configs/templates/php-fpm.toml /etc/confd/conf.d/php-fpm.toml
ADD configs/templates/supervisord.toml /etc/confd/conf.d/supervisord.toml
ADD configs/nginx.tmpl /etc/confd/templates/nginx.tmpl
ADD configs/php-fpm.tmpl /etc/confd/templates/php-fpm.tmpl
ADD configs/supervisord.tmpl /etc/confd/templates/supervisord.tmpl

# Setup our entrypoint into the container.
ADD entrypoint /usr/local/bin/entrypoint
RUN /bin/chmod 755 /usr/local/bin/entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint"]

# Expose the port to the Docker engine.
EXPOSE 8080
