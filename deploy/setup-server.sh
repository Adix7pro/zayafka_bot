#!/usr/bin/env bash
# Ubuntu serverni BIR MARTA sozlash: Node.js, PM2, Nginx, SSL, firewall
# Ishlatish:  sudo bash deploy/setup-server.sh
set -euo pipefail

DOMAIN="newworld.uz"
APP_DIR="/var/www/zayafka_bot"
APP_USER="${SUDO_USER:-$USER}"

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ sudo bilan ishga tushiring: sudo bash deploy/setup-server.sh"
  exit 1
fi

echo "==> 1. Paketlar"
apt-get update
apt-get install -y curl git nginx ufw certbot python3-certbot-nginx

echo "==> 2. Node.js 22"
if ! command -v node >/dev/null || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 18 ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
node -v

echo "==> 3. PM2"
npm install -g pm2

echo "==> 4. Firewall (faqat SSH, HTTP, HTTPS ochiq)"
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "==> 5. .env tekshiruvi"
if [ ! -f "$APP_DIR/.env" ]; then
  echo "❌ $APP_DIR/.env topilmadi. Avval yarating:"
  echo "   cp $APP_DIR/.env.example $APP_DIR/.env && nano $APP_DIR/.env"
  exit 1
fi
chmod 600 "$APP_DIR/.env"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"

echo "==> 6. Kutubxonalar va ishga tushirish (PM2)"
sudo -u "$APP_USER" bash -c "cd $APP_DIR && npm ci --omit=dev && pm2 startOrReload ecosystem.config.js && pm2 save"
# Server qayta yoqilganda ham avtomatik ishga tushsin
env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$APP_USER" --hp "$(eval echo ~"$APP_USER")"

echo "==> 7. Nginx"
cp "$APP_DIR/deploy/nginx.conf" "/etc/nginx/sites-available/$DOMAIN"
ln -sf "/etc/nginx/sites-available/$DOMAIN" "/etc/nginx/sites-enabled/$DOMAIN"
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "==> 8. SSL sertifikat (Let's Encrypt)"
echo "    Domen server IP'siga yo'naltirilgan bo'lishi SHART, aks holda bu qadam xato beradi."
certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --redirect --agree-tos --register-unsafely-without-email --non-interactive

echo ""
echo "✅ Tayyor! https://$DOMAIN"
echo "   Loglar:     pm2 logs zayafka_bot"
echo "   Yangilash:  bash $APP_DIR/deploy/deploy.sh"
