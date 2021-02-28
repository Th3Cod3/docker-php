FROM php:8-apache

# Install dev dependencies
RUN apt-get update --fix-missing && \
    apt-get install -y \
    $PHPIZE_DEPS \
    libcurl4-openssl-dev \
    libmagickwand-dev \
    libtool \
    libxml2-dev \
    libonig-dev

# Install production dependencies
RUN apt-get install -y \
    bash \
    curl \
    g++ \
    gcc \
    git \
    imagemagick \
    libc-dev \
    libpng-dev \
    make \
    mariadb-client \
    openssh-client \
    rsync \
    zlib1g-dev \
    vim \
    libzip-dev \
    zip \
    libpcre3-dev

# intall nodejs and npm
RUN curl -sL https://deb.nodesource.com/setup_14.x | sh
RUN apt-get install -y nodejs
RUN curl -sL https://www.npmjs.com/install.sh | sh


# Install PECL and PEAR extensions
RUN pecl channel-update pecl.php.net && \
    pecl install \
#    imagick \ waiting for PECL release
    xdebug \
    psr

# Install and enable php extensions
RUN docker-php-ext-enable \
#    imagick \ waiting for PECL release
    xdebug \
    psr

RUN docker-php-ext-configure zip
RUN docker-php-ext-install \
    curl \
    exif \
    iconv \
    mbstring \
    pdo \
    pdo_mysql \
    pcntl \
    tokenizer \
    xml \
    gd \
    zip \
    bcmath

# Install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

#install Vue-cli
RUN npm -g install @vue/cli

# Install PHP_CodeSniffer
RUN composer global require \
    squizlabs/php_codesniffer \
    laravel/installer

# Getting config files
RUN mkdir /var/.docker/
WORKDIR /var/.docker/
COPY ["*", "/var/.docker/"]
RUN cat /usr/local/etc/php/php.ini php.ini > /usr/local/etc/php/php.ini

## Variables
ARG DOMAIN
ARG SSL_SELF_SIGNED
ARG DOCUMENT_ROOT
ARG PHALCON
ENV SUBJ_CERT "/C=SE/ST=None/L=NB/O=None/CN=${DOMAIN}"

# Setup
RUN bash /var/.docker/config.sh

# Setup working directory
WORKDIR /var/www/html
