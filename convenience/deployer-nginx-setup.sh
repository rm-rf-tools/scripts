#!/bin/bash
DOMAIN=$1
EMAIL=$2
WEBHOOK_URL="webhook.$DOMAIN"
NGINX_CONF_NAME="${DOMAIN}.conf"
NGINX_CONF_FILE="/etc/nginx/sites-available/$NGINX_CONF_NAME"

echo "Domain: $DOMAIN"
echo "Webhook URL: $WEBHOOK"
echo "NGINX_CONF: $NGINX_CONF"
echo "NGINX_CONF_FILE: $NGINX_CONF_FILE"
SKIP_PROMPTS=false

# The main block of code to be added to the .bashrc file
read -r -d '' NGINX_TEMPLATE <<EOF
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
apt-get install -y python-certbot-nginx 


echo "Writing Nginx configuration..."
echo "$NGINX_TEMPLATE" | sudo tee "$NGINX_CONF_FILE" > /dev/null

echo "Enabling site..."

sudo rm /etc/nginx/sites-enabled/default
sudo ln -sf "$NGINX_CONF_FILE" "/etc/nginx/sites-enabled/"

echo "Testing and restarting Nginx..."
sudo nginx -t
sudo systemctl restart nginx


echo "Requesting SSL certificate for $DOMAIN and subdomains..."

# --- NON-INTERACTIVE CERTBOT COMMAND ---
sudo certbot --nginx --non-interactive --agree-tos -m $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN \
    -d webhook.$DOMAIN \
    -d staging.$DOMAIN \
    -d www.staging.$DOMAIN \
    --redirect

if [ $? -eq 0 ]; then
    echo "SSL certificate obtained and Nginx configured successfully."
    echo "Setup is complete."
else
    echo "Certbot failed to obtain an SSL certificate. Please check the output above."
    exit 1
fi
