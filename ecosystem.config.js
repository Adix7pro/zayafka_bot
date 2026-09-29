// PM2 sozlamasi: bot + sayt doimiy ishlashi, xato bo'lsa qayta ishga tushishi uchun
module.exports = {
  apps: [
    {
      name: 'zayafka_bot',
      script: 'index.js',
      // Faqat 1 nusxa! Bot polling rejimida va JSON baza bilan ishlaydi —
      // 2 ta nusxa bo'lsa Telegram 409 Conflict beradi va fayl buziladi
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '300M',
      restart_delay: 3000,
      time: true,
      env: {
        NODE_ENV: 'production',
      },
    },
  ],
};
