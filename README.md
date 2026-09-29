# zayafka_bot
sudo mkdir -p /var/www/zayafka_bot && sudo chown $USER:$USER /var/www/zayafka_bot && git clone https://github.com/Adix7pro/zayafka_bot.git /var/www/zayafka_bot
scp -r .env data tunnel USER@SERVER_IP:/var/www/zayafka_bot/
cd /var/www/zayafka_bot && sudo bash deploy/setup-server.sh
Telegram bot + sayt + Telegram Mini App. Foydalanuvchidan til va telefon raqamini so'rab saqlaydi.

- **Bot** — `/start` → til → telefon raqam; `/sayt` — sayt havolasi
- **Sayt** — https://newworld.uz (brauzerda raqam qo'lda yoziladi)
- **Mini App** — o'sha sahifa Telegram ichida ochilsa, raqam bir tugma bilan ulashiladi

Sayt internetga **Cloudflare Tunnel** orqali chiqadi: serverda port ochish, Nginx yoki SSL sozlash shart emas.

## Tuzilishi

```
index.js              — bot va saytni birga ishga tushiradi
bot.js                — Telegram bot
db.js                 — JSON baza (data/ papkasida)
web_site/web.js       — Express server + Mini App API
web_site/public/      — sayt sahifasi
ecosystem.config.js   — PM2 sozlamasi
deploy/               — server skriptlari

# git'ga yuklanmaydi (serverga qo'lda nusxalanadi):
.env                  — BOT_TOKEN, WEBAPP_URL
data/                 — foydalanuvchilar
tunnel/               — Cloudflare tunnel kaliti
```

## Ubuntu serverga o'rnatish (bir marta)

**1. Serverda** kodni GitHub'dan olish:

```bash
sudo mkdir -p /var/www/zayafka_bot && sudo chown $USER:$USER /var/www/zayafka_bot
git clone https://github.com/Adix7pro/zayafka_bot.git /var/www/zayafka_bot
```

**2. Kompyuterda** (loyiha papkasida) maxfiy fayllarni serverga nusxalash:

```bash
scp -r .env data tunnel USER@SERVER_IP:/var/www/zayafka_bot/
```

**3. Serverda** hammasini sozlash:

```bash
cd /var/www/zayafka_bot && sudo bash deploy/setup-server.sh
```

## Kodni yangilash

Kompyuterda o'zgartirib `git push`, keyin serverda:

```bash
bash /var/www/zayafka_bot/deploy/deploy.sh
```

## Foydali buyruqlar

```bash
pm2 logs zayafka_bot              # bot loglari
pm2 restart zayafka_bot           # botni qayta ishga tushirish
journalctl -u cloudflared -f      # tunnel loglari
sudo systemctl restart cloudflared
```

> ⚠️ Bot bir vaqtda faqat **bitta joyda** ishlashi mumkin — aks holda `409 Conflict` xatosi chiqadi.
