#!/usr/bin bash
if [[ $PHALCON == 1 ]]; then
  pecl install phalcon
  docker-php-ext-enable phalcon
  composer global require phalcon/devtools
fi

if [[ $SSL_SELF_SIGNED == 1 ]]; then
  echo "######## executing Self-Signed Certificate $DOMAIN ########"
  ## Edit files
  cat v3.ext | sed s/%%DOMAIN%%/"$DOMAIN"/g > _v3.ext
  cat server.conf | sed s/%%DOMAIN%%/"$DOMAIN"/g > _server.conf
  rm server.conf
  cat _server.conf | sed s/%%DOCUMENT_ROOT%%/"$DOCUMENT_ROOT"/g > server.conf

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
    -days 365 -sha256 -extfile _v3.ext

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
  mkdir $DOCUMENT_ROOT
  cat /etc/apache2/sites-available/000-default.conf |
    sed s/localhost/"$DOMAIN\n\tServerName $DOMAIN"/g > /etc/apache2/sites-available/_000-default.conf
  rm /etc/apache2/sites-available/000-default.conf
  echo "domain changed"
  cat /etc/apache2/sites-available/_000-default.conf |
    sed "s|/var/www/html|$DOCUMENT_ROOT|g" > /etc/apache2/sites-available/000-default.conf
  rm /etc/apache2/sites-available/_000-default.conf
  echo "document root changed"
fi

# Setting up apache
echo -e "127.0.0.1\t$DOMAIN" >> /etc/hosts
echo "ServerName $DOMAIN" >> /etc/apache2/apache2.conf
a2enmod rewrite
service apache2 restart
apache2ctl configtest
