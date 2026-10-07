# zayafka_bot
Telegram bot + sayt + Telegram Mini App. Foydalanuvchidan til va telefon raqamini so'rab saqlaydi.

- **Bot** — `/start` → til → telefon raqam; `/sayt` — sayt havolasi
- **Sayt** — https://newworld.uz (brauzerda raqam qo'lda yoziladi) bu endi ishlamaydi
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

## Ubuntu'da ishga tushirish

**To'liq qo'llanma: [docs/UBUNTU.md](docs/UBUNTU.md)**

Qisqacha (Ubuntu'da):

```bash
git clone https://github.com/Adix7pro/zayafka_bot.git /var/www/zayafka_bot
cd /var/www/zayafka_bot && cp .env.example .env && nano .env
sudo bash deploy/setup-server.sh
bash deploy/status.sh
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
> Everything will be good If you don't update url tables

