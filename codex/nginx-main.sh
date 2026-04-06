#!/bin/bash
touch /etc/nginx/.htpasswd

if [ -n "${BASIC_AUTH_PASS}" ]; then
  apt-get update &&\
  apt-get install -y apache2-utils &&\
  htpasswd -c -b /etc/nginx/.htpasswd $BASIC_AUTH_USER $BASIC_AUTH_PASS
fi

NGINX_CONFIG='
server {
    server_name '${DOMAIN}';
    listen       80 default_server;

    client_max_body_size  0;
    proxy_read_timeout 500000;
    proxy_connect_timeout 500000;
    proxy_send_timeout 510000;

    location / {
        auth_basic             "Restricted";
        auth_basic_user_file   .htpasswd;
        proxy_http_version    1.1;
        proxy_pass            http://codexapp:80/;
    }

    location /api/ {
        if ($request_method = "OPTIONS") {
            add_header Access-Control-Allow-Origin $http_origin always;

            add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
            add_header Access-Control-Allow-Headers "Authorization,DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Content-Range,Content-Disposition" always;
            add_header Access-Control-Allow-Credentials true;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 200;
        }

        if ($request_method = "GET") {
          add_header Access-Control-Allow-Origin $http_origin always;
          add_header Access-Control-Allow-Credentials true;
        }

        if ($request_method = "POST") {
          add_header Access-Control-Allow-Origin $http_origin always;
          add_header Access-Control-Allow-Credentials true;
        }


        proxy_http_version    1.1;
        proxy_pass            http://codex:8080/api/;

        auth_basic             "Restricted";
        auth_basic_user_file   .htpasswd;
    }
}
'

echo ${NGINX_CONFIG} > /etc/nginx/conf.d/${DOMAIN}.conf

if [ -n ${DOMAIN} ];then
  echo "==> Obtaining certificates for ${DOMAIN}"
  LETSENCRYPT_PATH=/etc/letsencrypt/live/${DOMAIN}

  if ! [ -d "${LETSENCRYPT_PATH}" ]; then
      apt-get -y install certbot python3-certbot-nginx
      certbot \
          --non-interactive\
          --agree-tos\
          --no-eff-email\
          --no-redirect\
          --email user@${DOMAIN}\
          -d ${DOMAIN}\
          --nginx
  fi

  if ! [ -e "${LETSENCRYPT_PATH}/privkey.pem" ]; then
      echo "The certificate does not exist"
      sleep 120
      exit 1
  fi

fi



service nginx stop;
nginx -g "daemon off;"
