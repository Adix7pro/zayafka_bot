#!/usr/bin/env bash
# Ubuntu serverni BIR MARTA sozlash: Node.js, PM2, Cloudflare Tunnel, firewall
# Ishlatish:  sudo bash deploy/setup-server.sh
#
# Oldin serverga (loyiha papkasiga) nusxalangan bo'lishi kerak:
#   .env                         — BOT_TOKEN, WEBAPP_URL=https://newworld.uz
#   data/                        — foydalanuvchilar bazasi (bo'lsa)
#   tunnel/<TUNNEL_ID>.json      — Cloudflare tunnel kaliti
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="${SUDO_USER:-$USER}"
TUNNEL_ID="8ca99220-9a74-4a84-851c-cb4b1fd493e8"

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ sudo bilan ishga tushiring: sudo bash deploy/setup-server.sh"
  exit 1
fi

echo "==> 0. Kerakli fayllar tekshiruvi ($APP_DIR)"
if [ ! -f "$APP_DIR/.env" ]; then
  echo "❌ $APP_DIR/.env topilmadi (kompyuterdan nusxalang yoki .env.example dan yarating)"
  exit 1
fi
if [ ! -f "$APP_DIR/tunnel/$TUNNEL_ID.json" ]; then
  echo "❌ $APP_DIR/tunnel/$TUNNEL_ID.json topilmadi (kompyuterdan nusxalang)"
  exit 1
fi

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

echo "==> 6. Cloudflare Tunnel (newworld.uz -> localhost:3000)"
if ! command -v cloudflared >/dev/null; then
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg -o /usr/share/keyrings/cloudflare-main.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
    > /etc/apt/sources.list.d/cloudflared.list
  apt-get update
  apt-get install -y cloudflared
fi

mkdir -p /etc/cloudflared
install -m 600 "$APP_DIR/tunnel/$TUNNEL_ID.json" "/etc/cloudflared/$TUNNEL_ID.json"
cat > /etc/cloudflared/config.yml <<EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/$TUNNEL_ID.json
ingress:
  - hostname: newworld.uz
    service: http://localhost:3000
  - hostname: www.newworld.uz
    service: http://localhost:3000
  - service: http_status:404
EOF

# systemd xizmati — server yoqilganda o'zi ishga tushadi
if [ ! -f /etc/systemd/system/cloudflared.service ]; then
  cloudflared service install
fi
systemctl enable cloudflared
systemctl restart cloudflared

sleep 5
echo ""
echo "==> Tekshiruv"
curl -s -o /dev/null -w "   Lokal sayt: HTTP %{http_code}\n" http://127.0.0.1:3000 || true
systemctl is-active --quiet cloudflared && echo "   Tunnel: ishlayapti" || echo "   ❌ Tunnel ishlamayapti: journalctl -u cloudflared -n 50"

echo ""
echo "✅ Tayyor! https://newworld.uz"
echo "   Bot loglari:     pm2 logs zayafka_bot"
echo "   Tunnel loglari:  journalctl -u cloudflared -f"
echo "   Yangilash:       bash $APP_DIR/deploy/deploy.sh"
