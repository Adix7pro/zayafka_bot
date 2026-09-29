#!/usr/bin/env bash
# Ubuntu serverni BIR MARTA to'liq sozlash: Node.js, PM2, bot + sayt, firewall, Cloudflare Tunnel
# Ishlatish:  sudo bash deploy/setup-server.sh
# Batafsil:   docs/UBUNTU.md
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="${SUDO_USER:-$USER}"

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ sudo bilan ishga tushiring: sudo bash deploy/setup-server.sh"
  exit 1
fi
if [ "$APP_USER" = "root" ]; then
  echo "❌ Oddiy foydalanuvchi nomidan sudo bilan ishga tushiring (root sifatida kirmasdan)"
  exit 1
fi

echo "==> 0. .env tekshiruvi ($APP_DIR)"
if [ ! -f "$APP_DIR/.env" ]; then
  echo "❌ $APP_DIR/.env topilmadi. Yarating:"
  echo "   cp $APP_DIR/.env.example $APP_DIR/.env && nano $APP_DIR/.env"
  exit 1
fi
grep -q '^BOT_TOKEN=.\+' "$APP_DIR/.env" || { echo "❌ .env ichida BOT_TOKEN bo'sh"; exit 1; }

echo "==> 1. Paketlar"
apt-get update
apt-get install -y curl git ufw ca-certificates gnupg

echo "==> 2. Node.js 22"
if ! command -v node >/dev/null || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 18 ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt-get install -y nodejs
fi
node -v

echo "==> 3. PM2"
command -v pm2 >/dev/null || npm install -g pm2

echo "==> 4. Firewall (faqat SSH ochiq — sayt tunnel orqali ishlaydi, port ochish shart emas)"
ufw allow OpenSSH
ufw --force enable

echo "==> 5. Bot + sayt (PM2)"
chmod 600 "$APP_DIR/.env"
mkdir -p "$APP_DIR/data"
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
sudo -u "$APP_USER" bash -c "cd '$APP_DIR' && npm ci --omit=dev && pm2 startOrReload ecosystem.config.js && pm2 save"
# Server qayta yoqilganda ham avtomatik ishga tushsin
env PATH="$PATH:/usr/bin" pm2 startup systemd -u "$APP_USER" --hp "$(eval echo ~"$APP_USER")"

echo "==> 6. Cloudflare Tunnel"
bash "$APP_DIR/deploy/setup-tunnel.sh"

echo ""
bash "$APP_DIR/deploy/status.sh" || true
