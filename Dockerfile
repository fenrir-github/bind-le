# fenrir/bind9-le
# bind9 + letsencrypt (certbot)
#
# VERSION 12.0.1
#
FROM debian:bullseye-slim
MAINTAINER Fenrir <dont@want.spam>

ENV  DEBIAN_FRONTEND noninteractive

# Configure APT
RUN  echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf &&\
  echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf &&\
  echo 'Aptitude::Recommends-Important "false";' >> /etc/apt/apt.conf &&\
  echo 'Aptitude::Suggests-Important "false";' >> /etc/apt/apt.conf &&\
# Install packages
  apt-get update &&\
  apt-get dist-upgrade -y &&\
  apt-get install -y -q bind9 bind9utils bind9-dnsutils certbot &&\
# Cleanning
  apt-get autoclean &&\
  apt-get clean &&\
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*.deb /tmp/* /var/tmp/* &&\
  rm -f /lib/systemd/system/certbot.service /lib/systemd/system/certbot.timer /etc/cron.d/certbot

RUN echo '#!/bin/bash'  >  /certbot-staging.sh &&\
  echo 'certbot certonly \
  --staging --dry-run \
  --rsa-key-size 4096 --no-autorenew \
  --noninteractive --agree-tos --manual \
  --preferred-challenges=dns --manual-auth-hook /dns-auth.sh \
  --post-hook /post-hook.sh \
  -d "$1"'  >> /certbot-staging.sh &&\
  chmod +x /certbot-staging.sh  &&\
  echo '#!/bin/bash'  >  /certbot.sh &&\
  echo 'certbot certonly --force-renewal \
  --rsa-key-size 4096 --no-autorenew \
  --noninteractive --agree-tos --manual \
  --preferred-challenges=dns --manual-auth-hook /dns-auth.sh \
  --post-hook /post-hook.sh \
  -d "$1"'  >> /certbot.sh &&\
  chmod +x /certbot.sh  &&\
  echo '#!/bin/bash'  >  /post-hook.sh &&\
  echo 'if [ -d "/etc/letsencrypt/archive" ]'  >> /post-hook.sh &&\
  echo 'then'  >> /post-hook.sh &&\
  echo '  chmod -R a+rX /etc/letsencrypt/archive'  >> /post-hook.sh &&\
  echo 'fi'  >> /post-hook.sh &&\
  echo 'if [ -d "/etc/letsencrypt/live" ]'  >> /post-hook.sh &&\
  echo 'then'  >> /post-hook.sh &&\
  echo '  chmod -R a+rX /etc/letsencrypt/live'  >> /post-hook.sh &&\
  echo '  cp -rfL /etc/letsencrypt/live /certificates/.'  >> /post-hook.sh &&\
  echo 'fi'  >> /post-hook.sh &&\
  chmod +x /post-hook.sh  &&\
  echo '#!/bin/bash'  >  /dns-auth.sh &&\
  echo 'if [ -z "$CERTBOT_DOMAIN" ] || [ -z "$CERTBOT_VALIDATION" ]'  >> /dns-auth.sh &&\
  echo 'then'  >> /dns-auth.sh &&\
  echo 'echo 'EMPTY DOMAIN OR VALIDATION''  >> /dns-auth.sh &&\
  echo 'exit -1'  >> /dns-auth.sh &&\
  echo 'fi'  >> /dns-auth.sh &&\
  echo 'echo "$CERTBOT_DOMAIN - $CERTBOT_VALIDATION"'  >> /dns-auth.sh &&\
  echo 'HOST="_acme-challenge"'  >> /dns-auth.sh &&\
  echo '/usr/bin/nsupdate << EOM'  >> /dns-auth.sh &&\
  echo 'server 127.0.0.1'  >> /dns-auth.sh &&\
  echo 'zone ${HOST}.${CERTBOT_DOMAIN}'  >> /dns-auth.sh &&\
  echo 'update delete ${HOST}.${CERTBOT_DOMAIN} TXT'  >> /dns-auth.sh &&\
  echo 'update add ${HOST}.${CERTBOT_DOMAIN} 300 TXT "${CERTBOT_VALIDATION}"'  >> /dns-auth.sh &&\
  echo 'send'  >> /dns-auth.sh &&\
  echo 'EOM'  >> /dns-auth.sh &&\
  echo 'sleep 10'  >> /dns-auth.sh &&\
  chmod +x /dns-auth.sh

VOLUME /etc/bind /var/lib/bind /certificates /etc/letsencrypt

EXPOSE 53/udp 53/tcp 953/tcp

ENTRYPOINT ["/usr/sbin/named","-g","-c","/etc/bind/named.conf","-u","bind"]

# docker run -d --name=bind9-le --restart=always \
  # --publish 2053:53/udp \
  # --publish 2053:53/tcp \
  # --publish 2953:953/tcp \
  # --volume <path to bind config>:/etc/bind \
  # --volume <path to bind zones>:/var/lib/bind \
  # --volume <path to letsencrypt>:/etc/letsencrypt \
  # --volume <path to certificates>:/certificates \
  # fenrir/bind9-le:12
# RELOAD zone: docker exec bind9-le rndc reload example.org
# FREEZE zone: docker exec bind9-le rndc freeze
# THAW zone: docker exec bind9-le rndc thaw
# REGISTER LE: docker exec bind9-le certbot register --non-interactive --agree-tos -m email@example.org
# UN-REGISTER: docker exec bind9-le certbot unregister --non-interactive --agree-tos -m email@example.org
# STAGING CRT: docker exec bind9-le /certbot-staging.sh *.example.org
# CERTIFICATE: docker exec bind9-le /certbot.sh *.example.org
# READ  CRT: docker exec bind9-le openssl x509 -in /etc/letsencrypt/live/example.org/cert.pem -text -noout
# READ LOGS: docker exec bind9-le cat /var/log/letsencrypt/letsencrypt.log
