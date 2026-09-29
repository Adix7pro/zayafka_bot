require('dotenv').config();
const { createBot } = require('./bot');
const { createWebApp } = require('./web_site/web');

const { BOT_TOKEN, WEBAPP_URL } = process.env;
const PORT = process.env.PORT || 3000;
// Serverda 127.0.0.1 — sayt faqat Nginx orqali ochiladi, portga to'g'ridan-to'g'ri kirib bo'lmaydi
const HOST = process.env.HOST || '127.0.0.1';

// ---------- Sayt / Mini App ----------
const server = createWebApp(BOT_TOKEN).listen(PORT, HOST, () => {
  console.log(`🌐 Sayt ishga tushdi: http://${HOST}:${PORT}`);
});

// ---------- Bot ----------
if (!BOT_TOKEN) {
  console.warn('⚠️  BOT_TOKEN .env faylida yo‘q — faqat sayt ishlayapti');
} else {
  if (WEBAPP_URL && !WEBAPP_URL.startsWith('https://')) {
    console.warn('⚠️  WEBAPP_URL https:// bilan boshlanishi kerak — Telegram http ni qabul qilmaydi');
  }
  const webAppUrl = WEBAPP_URL?.startsWith('https://') ? WEBAPP_URL : null;
  const bot = createBot(BOT_TOKEN, webAppUrl);

  // "/" bosilganda chiqadigan buyruqlar ro'yxati
  bot.telegram
    .setMyCommands([
      { command: 'start', description: 'Boshlash / Начать / Start' },
      { command: 'sayt', description: 'Sayt havolasi / Ссылка на сайт / Website' },
    ])
    .catch((err) => console.error('Buyruqlar o‘rnatilmadi:', err.message));

  // Barcha foydalanuvchilar uchun chap pastdagi "Ilova" menyu tugmasi
  if (webAppUrl) {
    bot.telegram
      .setChatMenuButton({ menuButton: { type: 'web_app', text: 'Ilova', web_app: { url: webAppUrl } } })
      .catch((err) => console.error('Menyu tugmasi o‘rnatilmadi:', err.message));
  }

  bot.launch(() => console.log('🤖 Bot ishga tushdi')).catch((err) => {
    // Masalan: token noto'g'ri yoki bot boshqa joyda ham ishlayapti (409 Conflict)
    console.error('❌ Bot ishga tushmadi:', err.message);
    process.exit(1);
  });

  // Server to'xtatilganda (pm2 restart ham) to'g'ri yopilishi uchun
  const shutdown = (signal) => {
    bot.stop(signal);
    server.close(() => process.exit(0));
  };
  process.once('SIGINT', () => shutdown('SIGINT'));
  process.once('SIGTERM', () => shutdown('SIGTERM'));
}
