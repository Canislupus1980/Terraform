#!/bin/sh

set -o errexit
set -o nounset
IFS=$(printf '\n\t')

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
printf '\nDocker installed successfully\n\n'

printf 'Waiting for Docker to start...\n\n'
sleep 5

# Docker Compose
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
printf '\nDocker Compose installed successfully\n\n'
sudo docker-compose -v

# Keycloak Install
mkdir -p /home/ubuntu/certs /home/ubuntu/nginx
sudo bash -c 'sudo cat <<EOT > /home/ubuntu/docker-compose.yml
version: "3"

services:
  nginx:
    image: nginx
    container_name: nginx
    restart: on-failure
    volumes:
      - ./nginx:/etc/nginx/conf.d
      - ./certs:/etc/nginx/certs
    ports:
      - "80:80"
      - "443:443"
    networks:
      - sso-network

  postgres:
    image: postgres
    container_name: postgres
    restart: always
    environment:
      POSTGRES_DB: "keycloak"
      POSTGRES_USER: "keycloak"
      POSTGRES_PASSWORD: "password"
      TZ: "Europe/Minsk"
    ports:
      - 5432:5432
    networks:
      - sso-network
    volumes:
      - ./data:/var/lib/postgresql/data

  keycloak:
    depends_on:
      - postgres
    container_name: keycloak
    entrypoint: /opt/keycloak/bin/kc.sh start --proxy edge --hostname-strict=false
    environment:
      HOSTNAME_STRICT_BACKCHANNEL: "true"
      DB_VENDOR: POSTGRES
      DB_ADDR: postgres
      DB_SCHEMA: public
      DB_DATABASE: "keycloak"
      DB_USER: "keycloak"
      DB_PASSWORD: "password"
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      PROXY_ADDRESS_FORWARDING: "true"
      TZ: "Europe/Minsk"
    image: quay.io/keycloak/keycloak:latest
    ports:
      - 8080:8080
    networks:
      - sso-network

# Networks to be created to facilitate communication between containers
networks:
  sso-network:
    external: true
EOT'

sudo docker network create --driver bridge --subnet=172.16.50.0/24 sso-network

sudo bash -c 'sudo cat <<EOT > /home/ubuntu/nginx/nginx.conf
upstream keycloak_backend {
  server keycloak:8080;
}
server {    
    listen 80;
    server_name keycloak.domen.com;
    location / {
        return 301 https://\$host\$request_uri;
    }
}
server {
    listen 443 ssl;
    server_name keycloak.domen.com;
    ssl_certificate /etc/nginx/certs/cert.crt;
    ssl_certificate_key /etc/nginx/certs/cert.key;
          proxy_set_header X-Forwarded-For \$proxy_protocol_addr;
          proxy_set_header X-Forwarded-Proto \$scheme;
          proxy_set_header Host \$host;
          proxy_buffers 4 256k;
          proxy_buffer_size 128k;
          proxy_busy_buffers_size 256k;

    location / {
          proxy_pass "http://keycloak_backend/";
    }
    location /admin {
          proxy_pass "http://keycloak_backend/admin";
    }

}
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !S>";
EOT'

sudo bash -c 'sudo cat <<EOT> /home/ubuntu/certs/cert.crt
-----BEGIN CERTIFICATE-----
MIIEFTCCAv2gAwIBAgIUVQCvKQf7fwOW0W57gLgcB1f/WZcwDQYJKoZIhvcNAQEL
...
-----END CERTIFICATE-----
EOT'

sudo bash -c 'sudo cat <<EOT> /home/ubuntu/certs/cert.key
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCooiC0uYGEeYvw
...
-----END PRIVATE KEY-----
EOT'

sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d
