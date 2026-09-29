#!/usr/bin/env bash
# Hamma narsa ishlayaptimi — bitta buyruq bilan tekshirish
# Ishlatish:  bash deploy/status.sh
DOMAIN="newworld.uz"
ok()   { echo "  ✅ $*"; }
fail() { echo "  ❌ $*"; FAILED=1; }
FAILED=0

echo "=== zayafka_bot holati ($(date '+%Y-%m-%d %H:%M')) ==="

if pm2 describe zayafka_bot 2>/dev/null | grep -q "status.*online"; then
  ok "Bot + sayt (PM2): online"
else
  fail "Bot + sayt (PM2) ishlamayapti  →  pm2 logs zayafka_bot --lines 50"
fi

code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://127.0.0.1:3000/)
[ "$code" = "200" ] && ok "Lokal sayt: HTTP 200" || fail "Lokal sayt: HTTP $code"

if systemctl is-active --quiet cloudflared; then
  ok "Cloudflare tunnel: ishlayapti"
else
  fail "Cloudflare tunnel ishlamayapti  →  sudo journalctl -u cloudflared -n 50"
fi

code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "https://$DOMAIN/")
if [ "$code" = "200" ]; then
  ok "https://$DOMAIN: HTTP 200"
else
  code_http=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "http://$DOMAIN/")
  if [ "$code_http" = "200" ]; then
    echo "  ⏳ http://$DOMAIN ishlayapti, https hali yo'q (Cloudflare SSL sertifikati kutilmoqda)"
  else
    fail "https://$DOMAIN: HTTP $code (http: $code_http)"
  fi
fi

exit $FAILED
