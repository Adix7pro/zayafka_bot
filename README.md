# zayafka_bot

Telegram bot + sayt + Telegram Mini App. Foydalanuvchidan til va telefon raqamini so'rab saqlaydi.

- **Bot** — `/start` → til → telefon raqam (kontakt tugmasi)
- **Sayt** — https://newworld.uz (brauzerda raqam qo'lda yoziladi)
- **Mini App** — o'sha sahifa Telegram ichida ochilsa, raqam bir tugma bilan ulashiladi

## Tuzilishi

```
index.js              — bot va saytni birga ishga tushiradi
bot.js                — Telegram bot
db.js                 — JSON baza (data/ papkasida)
web_site/web.js       — Express server + Mini App API
web_site/public/      — sayt sahifasi
ecosystem.config.js   — PM2 sozlamasi
deploy/               — server skriptlari va Nginx sozlamasi
data/                 — foydalanuvchilar (git'ga yuklanmaydi)
.env                  — token (git'ga yuklanmaydi)
```

## Kompyuterda ishga tushirish

```bash
npm install
cp .env.example .env   # BOT_TOKEN ni yozing
npm start
```

## Serverga o'rnatish (Ubuntu, bir marta)

1. Domen A yozuvi server IP'siga yo'naltirilgan bo'lsin (`newworld.uz` va `www.newworld.uz`).
2. Serverda:

```bash
sudo mkdir -p /var/www/zayafka_bot && sudo chown $USER:$USER /var/www/zayafka_bot
git clone https://github.com/Adix7pro/zayafka_bot.git /var/www/zayafka_bot
cd /var/www/zayafka_bot
cp .env.example .env && nano .env
sudo bash deploy/setup-server.sh
```

## Kodni yangilash

Kompyuterda o'zgartirib GitHub'ga `git push` qilasiz, keyin serverda:

```bash
bash /var/www/zayafka_bot/deploy/deploy.sh
```

## Foydali buyruqlar

```bash
pm2 logs zayafka_bot      # loglar
pm2 restart zayafka_bot   # qayta ishga tushirish
pm2 status                # holat
```

> ⚠️ Bot bir vaqtda faqat **bitta joyda** ishlashi mumkin. Serverda ishga tushirgach,
> kompyuteringizdagi botni o'chiring — aks holda `409 Conflict` xatosi chiqadi.
