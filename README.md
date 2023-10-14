# bind-le
Bind with LetsEncrypt integration for generating certificates using dns challenge

Do not use this as DNS server for clients, it's only a SOA

docker run -d --name=bind9-le --restart=always \
  --publish 2053:53/udp \
  --publish 2053:53/tcp \
  --publish 2953:953/tcp \
  --volume <path to bind config>:/etc/bind \
  --volume <path to bind zones>:/var/lib/bind \
  --volume <path to letsencrypt>:/etc/letsencrypt \
  --volume <path to certificates>:/certificates \
  fenrir/bind9-le:12

RELOAD zone: docker exec bind9-le rndc reload example.org

FREEZE zone: docker exec bind9-le rndc freeze
THAW zone: docker exec bind9-le rndc thaw
REGISTER LE: docker exec bind9-le certbot register --non-interactive --agree-tos -m email@example.org
UN-REGISTER: docker exec bind9-le certbot unregister --non-interactive --agree-tos -m email@example.org
STAGING CRT: docker exec bind9-le /certbot-staging.sh *.example.org
CERTIFICATE: docker exec bind9-le /certbot.sh *.example.org
READ  CRT: docker exec bind9-le openssl x509 -in /etc/letsencrypt/live/example.org/cert.pem -text -noout
READ LOGS: docker exec bind9-le cat /var/log/letsencrypt/letsencrypt.log
