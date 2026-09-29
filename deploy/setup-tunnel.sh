#!/usr/bin/env bash
# Cloudflare Tunnel: newworld.uz -> http://localhost:3000 (systemd xizmati sifatida)
# Ishlatish:  sudo bash deploy/setup-tunnel.sh
#
# Ikki holatda ishlaydi:
#   A) tunnel/<ID>.json kaliti bor (boshqa kompyuterdan nusxalangan) — shu tunnel ishlatiladi
#   B) kalit yo'q — Cloudflare'ga kirib (brauzer havolasi), yangi tunnel shu serverning o'zida yaratiladi
set -euo pipefail

DOMAIN="newworld.uz"
TUNNEL_NAME="newworld"
LOCAL_URL="http://localhost:3000"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CF_DIR="/etc/cloudflared"

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ sudo bilan ishga tushiring: sudo bash deploy/setup-tunnel.sh"
  exit 1
fi

echo "==> 1. cloudflared dasturi"
if ! command -v cloudflared >/dev/null; then
  mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg -o /usr/share/keyrings/cloudflare-main.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
    > /etc/apt/sources.list.d/cloudflared.list
  apt-get update
  apt-get install -y cloudflared
fi
cloudflared --version

mkdir -p "$CF_DIR"
CRED_FILE=$(ls "$APP_DIR"/tunnel/*.json 2>/dev/null | head -1 || true)

if [ -n "$CRED_FILE" ]; then
  echo "==> 2. Mavjud tunnel kaliti ishlatiladi: $CRED_FILE"
  TUNNEL_ID=$(sed -n 's/.*"TunnelID"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CRED_FILE")
  [ -n "$TUNNEL_ID" ] || { echo "❌ $CRED_FILE ichida TunnelID topilmadi"; exit 1; }
  install -m 600 "$CRED_FILE" "$CF_DIR/$TUNNEL_ID.json"
else
  echo "==> 2. Tunnel kaliti yo'q — shu serverda yangi tunnel yaratamiz"
  if [ ! -f /root/.cloudflared/cert.pem ]; then
    echo "   Quyida chiqadigan havolani istalgan brauzerda oching va $DOMAIN ni tanlab 'Authorize' bosing:"
    cloudflared tunnel login
  fi
  if cloudflared tunnel list 2>/dev/null | awk '{print $2}' | grep -qx "$TUNNEL_NAME"; then
    echo "❌ Cloudflare'da '$TUNNEL_NAME' tunneli allaqachon bor, lekin uning kaliti bu serverda yo'q."
    echo "   Yo eski kompyuterdan tunnel/<ID>.json ni nusxalang,"
    echo "   yo eski tunnelni o'chiring:  sudo cloudflared tunnel delete -f $TUNNEL_NAME  — va skriptni qayta ishga tushiring."
    exit 1
  fi
  cloudflared tunnel create "$TUNNEL_NAME"
  TUNNEL_ID=$(cloudflared tunnel list 2>/dev/null | awk -v n="$TUNNEL_NAME" '$2==n {print $1}')
  cp "/root/.cloudflared/$TUNNEL_ID.json" "$CF_DIR/$TUNNEL_ID.json"
  chmod 600 "$CF_DIR/$TUNNEL_ID.json"
  # Kalitning zaxira nusxasi loyiha papkasida (git'ga tushmaydi)
  mkdir -p "$APP_DIR/tunnel" && cp "$CF_DIR/$TUNNEL_ID.json" "$APP_DIR/tunnel/"
fi
echo "   Tunnel ID: $TUNNEL_ID"

echo "==> 3. DNS: $DOMAIN va www.$DOMAIN -> tunnel"
if [ -f /root/.cloudflared/cert.pem ]; then
  cloudflared tunnel route dns --overwrite-dns "$TUNNEL_ID" "$DOMAIN"
  cloudflared tunnel route dns --overwrite-dns "$TUNNEL_ID" "www.$DOMAIN"
else
  echo "   (o'tkazib yuborildi: DNS yozuvlari tunnel yaratilganda qo'shilgan)"
fi

echo "==> 4. Sozlama: $CF_DIR/config.yml"
cat > "$CF_DIR/config.yml" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CF_DIR/$TUNNEL_ID.json
ingress:
  - hostname: $DOMAIN
    service: $LOCAL_URL
  - hostname: www.$DOMAIN
    service: $LOCAL_URL
  - service: http_status:404
EOF
cloudflared tunnel --config "$CF_DIR/config.yml" ingress validate

echo "==> 5. systemd xizmati (server yoqilganda o'zi ishga tushadi)"
[ -f /etc/systemd/system/cloudflared.service ] || cloudflared service install
systemctl daemon-reload
systemctl enable cloudflared
systemctl restart cloudflared
sleep 5
if systemctl is-active --quiet cloudflared; then
  echo "✅ Tunnel ishlayapti: https://$DOMAIN"
else
  echo "❌ Tunnel ishga tushmadi. Loglar: journalctl -u cloudflared -n 50"
  exit 1
fi
