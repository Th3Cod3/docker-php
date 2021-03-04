#!/usr/bin bash
if [[ $PHALCON == 1 ]]; then
    pecl install phalcon
    docker-php-ext-enable phalcon
    composer global require phalcon/devtools
fi
mkdir $DOCUMENT_ROOT
if [[ $SSL_SELF_SIGNED == 1 ]]; then
    echo "######## executing Self-Signed Certificate $DOMAIN ########"
    ## Edit files
    sed -i "s|%%DOMAIN%%|$DOMAIN|g" v3.ext
    sed -i "s|%%DOMAIN%%|$DOMAIN|g; s|%%DOCUMENT_ROOT%%|$DOCUMENT_ROOT|g" server.conf

    ## Create ROOT certificate
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key \
        -sha256 -days 1024 -out rootCA.pem -subj $SUBJ_CERT

    ## Create DOMAIN certificate
    openssl req -new -newkey rsa:2048 -sha256 -nodes \
        -keyout server.key \
        -out server.csr -subj $SUBJ_CERT
    openssl x509 -req -in server.csr -CA rootCA.pem \
        -CAkey rootCA.key -CAcreateserial -out server.crt \
        -days 365 -sha256 -extfile v3.ext

    # Copy files
    cp server.key /etc/ssl/private/server.key
    cp server.crt /etc/ssl/certs/server.crt
    cp server.conf /etc/apache2/sites-available/$DOMAIN.conf

    # Setting up apache
    a2enmod ssl
    a2ensite $DOMAIN.conf
    a2dissite 000-default.conf
    a2dissite default-ssl.conf
    echo "######## Setup apache VirtualHost $DOMAIN #########"
else
    echo "######## Without SSL ########"
    sed "s|localhost|$DOMAIN\n\tServerName $DOMAIN|g; s|/var/www/html|$DOCUMENT_ROOT|g" \
        /etc/apache2/sites-available/000-default.conf
fi

# Setting up apache
echo -e "127.0.0.1\t$DOMAIN" >>/etc/hosts
echo "ServerName $DOMAIN" >>/etc/apache2/apache2.conf
a2enmod rewrite
service apache2 restart
apache2ctl configtest
