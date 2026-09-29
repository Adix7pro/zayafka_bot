# Ubuntu'da ishga tushirish (Cloudflare Tunnel varianti)

Bu qo'llanma botni, saytni va Telegram Mini App'ni Ubuntu kompyuter/serverda
**Cloudflare Tunnel** orqali `https://newworld.uz` da ishlatishni bosqichma-bosqich tushuntiradi.

## Qanday ishlaydi

```
Foydalanuvchi ──► https://newworld.uz ──► Cloudflare ══(tunnel)══► Ubuntu: cloudflared ──► localhost:3000 (bot + sayt)
Telegram ◄──────────────────────────────────────────────────────── Ubuntu: bot (polling)
```

- **Bot + sayt** — bitta Node.js jarayoni (`index.js`), **PM2** boshqaradi.
- **cloudflared** — Ubuntu'dan Cloudflare'ga o'zi ulanadi. Shuning uchun:
  oq IP, routerda port ochish, Nginx, SSL sozlash **kerak emas**.
- Ikkalasi ham server yoqilganda **avtomatik** ishga tushadi.

## Talablar

- Ubuntu 22.04 / 24.04, internet, `sudo` huquqi
- `newworld.uz` Cloudflare'da (NS: `anita.ns.cloudflare.com`, `porter.ns.cloudflare.com`)
- Bot tokeni (@BotFather)

---

## 1-qadam. Kodni GitHub'dan olish (Ubuntu'da)

```bash
sudo apt update && sudo apt install -y git
sudo mkdir -p /var/www/zayafka_bot && sudo chown $USER:$USER /var/www/zayafka_bot
git clone https://github.com/Adix7pro/zayafka_bot.git /var/www/zayafka_bot
cd /var/www/zayafka_bot
```

> Papka bo'sh bo'lmasa (`destination path already exists`) — kodni yonidan qo'shing:
> ```bash
> git clone https://github.com/Adix7pro/zayafka_bot.git /tmp/zb && cp -rn /tmp/zb/. /var/www/zayafka_bot/ && rm -rf /tmp/zb
> ```

## 2-qadam. Maxfiy fayllar

Bular GitHub'da **yo'q** (xavfsizlik uchun), serverga alohida qo'yiladi:

| Fayl | Nima | Majburiymi |
|---|---|---|
| `.env` | `BOT_TOKEN`, `WEBAPP_URL=https://newworld.uz` | ✅ ha |
| `data/` | foydalanuvchilar bazasi | yo'q (bo'lmasa bo'sh boshlanadi) |
| `tunnel/<ID>.json` | Cloudflare tunnel kaliti | yo'q (bo'lmasa 3-qadamda yangisi yaratiladi) |

**Variant A — eski kompyuterdan nusxalash** (Windows PowerShell'da, loyiha papkasida):

```bash
scp -r .env data tunnel adham1011@192.168.51.77:/var/www/zayafka_bot/
```

**Variant B — noldan** (Ubuntu'da):

```bash
cp .env.example .env
nano .env        # BOT_TOKEN ni yozing, Ctrl+O, Enter, Ctrl+X
```

## 3-qadam. Hammasini sozlash (bitta buyruq)

```bash
cd /var/www/zayafka_bot && sudo bash deploy/setup-server.sh
```

Skript o'zi bajaradi:

1. Node.js 22, PM2, firewall (faqat SSH ochiq)
2. Kutubxonalar (`npm ci`) va bot + saytni PM2'da ishga tushirish
3. `cloudflared` o'rnatish, tunnelni sozlash, `newworld.uz` DNS'ini tunnelga yo'naltirish
4. Oxirida holatni tekshiradi

`tunnel/` kaliti bo'lmasa, skript Cloudflare havolasini chiqaradi — uni brauzerda oching,
`newworld.uz` ni tanlab **Authorize** bosing, skript davom etadi.

Oxirida shunday chiqishi kerak:

```
  ✅ Bot + sayt (PM2): online
  ✅ Lokal sayt: HTTP 200
  ✅ Cloudflare tunnel: ishlayapti
  ✅ https://newworld.uz: HTTP 200
```

---

## Kundalik ishlar

| Nima qilish | Buyruq |
|---|---|
| Holatni tekshirish | `bash /var/www/zayafka_bot/deploy/status.sh` |
| GitHub'dan yangilash | `bash /var/www/zayafka_bot/deploy/deploy.sh` |
| Bot loglari | `pm2 logs zayafka_bot` |
| Botni qayta ishga tushirish | `pm2 restart zayafka_bot` |
| Tunnel loglari | `sudo journalctl -u cloudflared -f` |
| Tunnelni qayta ishga tushirish | `sudo systemctl restart cloudflared` |
| `.env` ni o'zgartirgandan keyin | `pm2 restart zayafka_bot --update-env` |

**Yangilash tartibi:** kompyuterda kodni o'zgartirasiz → `git push` → serverda `deploy.sh`.

## Zaxira nusxa (backup)

Foydalanuvchilar `data/` papkasida. Vaqti-vaqti bilan nusxa oling:

```bash
tar czf ~/zayafka_backup_$(date +%F).tar.gz -C /var/www/zayafka_bot data .env tunnel
```

---

## Muammolar va yechimlar

| Belgi | Sabab | Yechim |
|---|---|---|
| Logda `409 Conflict` | Bot boshqa joyda ham ishlayapti (masalan, eski kompyuterda) | Ikkinchisini o'chiring — bot faqat **bitta** joyda ishlashi mumkin |
| Brauzerda `ERR_SSL_VERSION_OR_CIPHER_MISMATCH` / "Unsupported protocol" | Cloudflare SSL sertifikati hali chiqmagan | Kuting (odatda bir necha soat). Cloudflare → SSL/TLS → Edge Certificates: **Active** bo'lishi kerak |
| `ERR_NAME_NOT_RESOLVED` / `NXDOMAIN` | DNS hali tarqalmagan yoki NS noto'g'ri | ahost.uz → Domen → NS: `anita.ns.cloudflare.com`, `porter.ns.cloudflare.com` |
| Cloudflare **Error 1033** | Tunnel ishlamayapti | `sudo systemctl restart cloudflared`, `sudo journalctl -u cloudflared -n 50` |
| Cloudflare **502 Bad Gateway** | Tunnel bor, lekin bot/sayt o'chiq | `pm2 restart zayafka_bot`, `pm2 logs zayafka_bot` |
| Mini App ochilmaydi | `WEBAPP_URL` noto'g'ri yoki https yo'q | `.env`: `WEBAPP_URL=https://newworld.uz`, keyin `pm2 restart zayafka_bot --update-env` |
| Buyruq oxirida `(http://...sh/)` | Nusxa olishda messenjer havola qo'shib yuborgan | Buyruqni qo'lda yozing yoki qavsdagi qismini o'chiring |
