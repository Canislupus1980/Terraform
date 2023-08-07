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
BQAwgZkxCzAJBgNVBAYTAkJZMRMwEQYDVQQIDApTb21lLVN0YXRlMQ4wDAYDVQQH
DAVNaW5zazESMBAGA1UECgwJTXlDb21wYW55MQ8wDQYDVQQLDAZEZXZPcHMxHDAa
BgNVBAMME2tleWNsb2FrLmpmcm9nLnNob3AxIjAgBgkqhkiG9w0BCQEWE3NlcmVu
a2lqYkBnbWFpbC5jb20wHhcNMjMwODA3MDgzMDMyWhcNMjQwODA2MDgzMDMyWjCB
mTELMAkGA1UEBhMCQlkxEzARBgNVBAgMClNvbWUtU3RhdGUxDjAMBgNVBAcMBU1p
bnNrMRIwEAYDVQQKDAlNeUNvbXBhbnkxDzANBgNVBAsMBkRldk9wczEcMBoGA1UE
AwwTa2V5Y2xvYWsuamZyb2cuc2hvcDEiMCAGCSqGSIb3DQEJARYTc2VyZW5raWpi
QGdtYWlsLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKiiILS5
gYR5i/A8Ex/fPOh53u/xrMAON9Q8YFIEYQiSvcbU3tbszbMIK1NR3ypX/6tNQpif
di2KhYEnLgDzQjDnHGvW7iE836FV/N6hkmNhBs7hEWRGPqsZRcKiqtaiuTL/foaN
38q1HFvO7xx4YHqekxt6zPg3BA/Zypy8B0oGyRpe0oB84/BYwHtJ1dJaNm6t9aRg
laNN9xlKqmAgBuphqyLKal3d0+9zrw3NjynDocUN/Zk2y7OIwSJhShKWdLM1aI9n
N7eVj3aHJgtWZc7WQ6zbmNPZvr6GoSlBqL2gXLokgZt9IzF1zZbZeXbyppWJ4h7c
1b7pN2+d5aQL9rECAwEAAaNTMFEwHQYDVR0OBBYEFLIWH+BWj7/eh7F8vEVdV/ln
//pYMB8GA1UdIwQYMBaAFLIWH+BWj7/eh7F8vEVdV/ln//pYMA8GA1UdEwEB/wQF
MAMBAf8wDQYJKoZIhvcNAQELBQADggEBAHirO5kNe65WP+ed92ffnIEhsKT9tPei
tP4o+4U9+LIdxchVo/cpOvEgBgjjP3mTviT8wTXqWwP9ZoPVv82Dg7CCRNl56YXn
Q2EEhGz8EUg1xR591whstxr681njA1cLitsjFI2OHrLxILFmIzQhP5aDEeiCVd4Y
PhqS/ioV76t5XnVLtrJpWSashAJKaqNEfP37HeQNKAARwEHFQV1FxhX5f9DnkK/+
Kko37Y439MWV0qOx6N3yXjiSu4XR/gm0OhQNaMLWibpShOZPuSyx4kr/RVWHOZCr
ROhFmd5IfEK9AMbosAVtqlNwk1Z/KkUaXFRu9ZxZWJ/0Lxggy1riaXM=
-----END CERTIFICATE-----
EOT'

sudo bash -c 'sudo cat <<EOT> /home/ubuntu/certs/cert.key
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCooiC0uYGEeYvw
PBMf3zzoed7v8azADjfUPGBSBGEIkr3G1N7W7M2zCCtTUd8qV/+rTUKYn3YtioWB
Jy4A80Iw5xxr1u4hPN+hVfzeoZJjYQbO4RFkRj6rGUXCoqrWorky/36Gjd/KtRxb
zu8ceGB6npMbesz4NwQP2cqcvAdKBskaXtKAfOPwWMB7SdXSWjZurfWkYJWjTfcZ
SqpgIAbqYasiympd3dPvc68NzY8pw6HFDf2ZNsuziMEiYUoSlnSzNWiPZze3lY92
hyYLVmXO1kOs25jT2b6+hqEpQai9oFy6JIGbfSMxdc2W2Xl28qaVieIe3NW+6Tdv
neWkC/axAgMBAAECggEAELep6GCvj1OBZPp/ptw5rI5QZJcf2hZOwJKPtfHLMM9j
Uu/Ne58UMVhw+xyVtBvvM6tAG+NLEu61l30r2VpESJbQwXwYNWFUhikBHY0E9ycq
Rp4XXEp+cfXabZY0u3x8QasEfxBXjD/yJMPZ/oeMgPtxd/rvkPfbRjsAFBOr4VGr
olW8nyVPUCBrE9npXovdsiaTzaaTJ8VXhNfcxRvSruyfK+ty6zq+E4c/zmwk3+yZ
dmr4hWY1hKQDJK3EjgrLVRbb8ydD7n5+SQw/iE0cn6/j5OlCxgsSjvBNjXYb3T4t
JSI3fmUUuO2LeAIdORngyu/gZ69ZwdETfYTUvhhipQKBgQDbY25NipDks8LSAACC
MvxzmPZZljhw7rfuKhZU4vn17ynFw1iVpHLmMjnrL/+lNaC/wpXviZUXMkk3+ZOK
MOZzoqgbDnTP6Q0Rq6nfystF8UtQDwGrX5GJ5Jk89vGdJACVXPLT+gX80STqmVg6
SkLv0TMmTcMWJvrXy7Ys6a5ERwKBgQDExl7tgDp4JYutxYWQmZqrEwRoT3jE51E5
55/C30cYFXLWu6mDcvB9+24KGFve1uF1fl+qwF0lwSN9T7KhlpyGQC6x8OG8GU2N
sJnfbbaMoAPG8RBa8VAud7ObhwCs3KWOQdWRtZ31ARGhKnDEbSU3nxOoF+Cs/R/F
ycxJdRdBRwKBgBp7gyobCuiAhojg9S7CRtURZtNjncaMGmnGbNGsYG3+g7VaokvW
AQSmlXU9YwenVJMxQvYaToPxTwNRviyVQIw+2zoA4brjL++tICFikm0L9oJgfVwZ
ejECBjlkub+1Q9jD0pAiAy0EdgdXoV3P7wqR3zHFe0ImTGtWLNR5FM8rAoGAaTzW
hBqyKpOZ8mPTHRSpfZj8IHVwV46HCHryHJyhPyYpduKCtESCjj4sCcYhTDqL9fSS
YZXju09iFaDMHlOYfsxQrOXxNFIsAf1TLgVVPjxOCNXgM2MfyNpH+oPnPov7Fuvq
trT1N5VMwm8aRFNDNk4jiyDKDnqJxZQ5Z4fx2f0CgYBnQKxl3leDoQCzJlLStTvk
I+FL3+fphgYu6NY4jOZDbbUjcNMDCMBmeYA3QYvd48ht7JowDWqfzOQeJKIjJgRh
AI/MG7eW3/RLqevBjquKSxeMufZFJPGfUuF3gEKQEogJ+qmTZjNtYyvC1BWZ1cvk
E758qthcuMPrmRq3VkpnlQ==
-----END PRIVATE KEY-----
EOT'

sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d
