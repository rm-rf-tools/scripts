#!/bin/bash

DOMAIN=$1
WEBHOOK_URL="webhook.$DOMAIN"
NGINX_CONF_NAME="${DOMAIN}.conf"
NGINX_CONF_FILE="/etc/nginx/sites-available/$NGINX_CONF_NAME"

echo "Domain: $DOMAIN"
echo "Webhook URL: $WEBHOOK"
echo "NGINX_CONF: $NGINX_CONF"
echo "NGINX_CONF_FILE: $NGINX_CONF_FILE"
SKIP_PROMPTS=false

# --- Argument Parsing ---
if [[ "$1" == "-y" || "$1" == "--yes" ]]; then
  SKIP_PROMPTS=true
  echo "Running in non-interactive mode (-y). Prompts will be skipped."
fi


# The main block of code to be added to the .bashrc file
read -r -d '' NGINX_TEMPLATE <<'EOF'
server {
    listen 80;
    server_name $WEBHOOK_URL;


    location / {
        proxy_pass http://127.0.0.1:9000;
        include /etc/nginx/proxy_params;
        proxy_redirect off;
    }
}

server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;


    location / {
        proxy_pass http://127.0.0.1:8850;
        include /etc/nginx/proxy_params;
        proxy_redirect off;
    }
}

server {
    listen 80;
    server_name staging.$DOMAIN www.staging.$DOMAIN;


    location / {
        proxy_pass http://127.0.0.1:8851;
        include /etc/nginx/proxy_params;
        proxy_redirect off;
    }
}



EOF



apt-get update -y
apt-get install -y nginx ufw 
apt install python-certbot-nginx 

sudo rm /etc/nginx/sites-enabled/default


sudo nginx -t
sudo systemctl restart nginx
sudo ln -s /etc/nginx/sites-available/ /etc/nginx/sites-enabled

sudo certbot --nginx -d "*.$DOMAIN" -d $DOMAIN
