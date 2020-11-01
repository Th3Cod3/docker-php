FROM php:7.3-apache

# Install dev dependencies
RUN apt-get update --fix-missing && \
    apt-get install -y \
    $PHPIZE_DEPS \
    libcurl4-openssl-dev \
    libmagickwand-dev \
    libtool \
    libxml2-dev

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
    libzip-dev

# Install PECL and PEAR extensions
RUN pecl install \
    imagick \
    xdebug

# Install and enable php extensions
RUN docker-php-ext-enable \
    imagick \
    xdebug
RUN docker-php-ext-configure zip --with-libzip
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

# Setting up certificate
RUN mkdir /var/server-conf/
WORKDIR /var/server-conf/
COPY ["devops/server.conf", "devops/v3.ext", "/var/server-conf/"]

## Variables
ENV DOMAIN dev.th3cod3.com
ENV DOCUMENT_ROOT /
ENV SUBJ_CERT "/C=SE/ST=None/L=NB/O=None/CN=${DOMAIN}"

## Edit files
RUN cat v3.ext | sed s/%%DOMAIN%%/"$DOMAIN"/g > _v3.ext
RUN cat server.conf | sed s/%%DOMAIN%%/"$DOMAIN"/g > _server.conf

## Create ROOT certificate
RUN openssl genrsa -out rootCA.key 2048
RUN openssl req -x509 -new -nodes -key rootCA.key \
    -sha256 -days 1024 -out rootCA.pem -subj ${SUBJ_CERT}

## Create DOMAIN certificate
RUN openssl req -new -newkey rsa:2048 -sha256 -nodes \
    -keyout server.key \
    -out server.csr -subj ${SUBJ_CERT}
RUN openssl x509 -req -in server.csr -CA rootCA.pem \
    -CAkey rootCA.key -CAcreateserial -out server.crt \
    -days 365 -sha256 -extfile _v3.ext

# Copy files
RUN cp server.key /etc/ssl/private/server.key && \
    cp server.crt /etc/ssl/certs/server.crt && \
    cp _server.conf /etc/apache2/sites-available/${DOMAIN}.conf

# Setting up apache
RUN echo -e "127.0.0.1\t${DOMAIN}" >> /etc/hosts
RUN echo "ServerName ${DOMAIN}" >> /etc/apache2/apache2.conf
RUN a2enmod ssl && \
    a2enmod rewrite && \
    a2ensite ${DOMAIN}.conf && \
    a2dissite 000-default.conf && \
    a2dissite default-ssl.conf && \
    service apache2 restart && \
    apache2ctl configtest

# Print CA certificate
RUN cat /var/server-conf/rootCA.pem

# COPY ["src/composer.json", "src/composer.json", "/var/www/html/"]
# RUN composer install

# Final workdir
WORKDIR /var/www/html