# Docker
If you want to use the containers you can just run the following instruction:

* Edit container args into `docker-compose.yml`
  * `DOMAIN=<domain>` For the domain request
  * `SSL_SELF_SIGNED=<0|1>` 1 to set up self-signed certificate or 0 to set without ssl
  * `PHALCON=<0|1>` 1 to enable phalcon
  * `DOCUMENT_ROOT=<0|1>` Here come de entry point of Apache
* Run docker-compose
  * `docker-compose up -d` if it's the first time
  * `docker-compose up -d --build` to build the container again

## if you use the self-signed certificate
* Add the host, override DNS.
  * Windows: `C:\Windows\System32\drivers\etc\host` open as Administrator.
  * Mac OS/Linux: `/etc/hosts`.
* Get the rootCA.pem from the container `/var/server-conf/rootCA.pem`.
  * `docker-compose exec dtt cat /var/server-conf/rootCA.pem`
* Save the key and import to the Thrusted Root Certification Authorities