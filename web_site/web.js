const crypto = require('crypto');
const path = require('path');
const express = require('express');
const { tgUsers, webUsers, upsertTgUser, normalizePhone } = require('../db');

const LANGS = ['uz', 'ru', 'en'];

// Telegram yuborgan ma'lumot haqiqatan Telegramdan kelganini tekshiradi
// (initData va requestContact javobi uchun bir xil algoritm).
// https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
function checkTelegramData(raw, token, maxAgeSec) {
  if (!raw || !token) return null;
  const params = new URLSearchParams(raw);
  const hash = params.get('hash');
  if (!hash) return null;
  params.delete('hash');

  const dataCheckString = [...params.entries()]
    .sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0))
    .map(([k, v]) => `${k}=${v}`)
    .join('\n');

  const secret = crypto.createHmac('sha256', 'WebAppData').update(token).digest();
  const expected = crypto.createHmac('sha256', secret).update(dataCheckString).digest('hex');

  if (hash.length !== expected.length) return null;
  if (!crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(expected))) return null;

  const authDate = Number(params.get('auth_date'));
  if (!authDate || Date.now() / 1000 - authDate > maxAgeSec) return null;

  return Object.fromEntries(params);
}

function createWebApp(token) {
  const app = express();
  app.use(express.json());
  app.use(express.static(path.join(__dirname, 'public')));

  // ================= Oddiy sayt =================
  app.post('/api/register', (req, res) => {
    const { lang, phone } = req.body || {};
    if (!LANGS.includes(lang)) {
      return res.status(400).json({ ok: false, error: 'invalid_lang' });
    }
    const normalized = normalizePhone(phone);
    if (!normalized) {
      return res.status(400).json({ ok: false, error: 'invalid_phone' });
    }

    const prev = webUsers.data[normalized];
    webUsers.data[normalized] = {
      ...prev,
      phone: normalized,
      lang,
      registered_at: prev?.registered_at || new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };
    webUsers.save();

    res.json({ ok: true, phone: normalized });
  });

  // ================= Telegram Mini App =================
  // Har bir so'rovda initData tekshiriladi — foydalanuvchini soxtalashtirib bo'lmaydi
  function tgAuth(req, res, next) {
    const data = checkTelegramData(req.body?.initData, token, 24 * 60 * 60);
    if (!data?.user) return res.status(401).json({ ok: false, error: 'unauthorized' });
    req.tgUser = JSON.parse(data.user);
    next();
  }

  const publicUser = (u) => ({ ok: true, lang: u?.lang || null, phone: u?.phone || null });

  app.post('/api/tg/me', tgAuth, (req, res) => {
    res.json(publicUser(tgUsers.data[req.tgUser.id]));
  });

  app.post('/api/tg/lang', tgAuth, (req, res) => {
    const { lang } = req.body;
    if (!LANGS.includes(lang)) return res.status(400).json({ ok: false, error: 'invalid_lang' });

    const prev = tgUsers.data[req.tgUser.id];
    const user = upsertTgUser(req.tgUser, { lang, step: prev?.phone ? 'done' : 'waiting_phone' });
    res.json(publicUser(user));
  });

  app.post('/api/tg/contact', tgAuth, (req, res) => {
    const id = req.tgUser.id;
    const { response } = req.body;

    // Yangi Telegram ilovalari imzolangan kontakt qaytaradi — uni tekshirib saqlaymiz
    if (response) {
      const data = checkTelegramData(response, token, 10 * 60);
      if (!data?.contact) return res.status(400).json({ ok: false, error: 'invalid_contact' });

      const contact = JSON.parse(data.contact);
      if (contact.user_id !== id) return res.status(403).json({ ok: false, error: 'not_yours' });

      const prev = tgUsers.data[id];
      const user = upsertTgUser(req.tgUser, {
        lang: prev?.lang || 'uz',
        phone: normalizePhone(contact.phone_number),
        step: 'done',
        registered_at: prev?.registered_at || new Date().toISOString(),
      });
      return res.json(publicUser(user));
    }

    // Eski ilovalarda imzo yo'q — bot kontaktni qabul qilib saqlagan bo'ladi
    const user = tgUsers.data[id];
    if (user?.phone) return res.json(publicUser(user));
    res.status(404).json({ ok: false, error: 'not_yet' });
  });

  return app;
}

module.exports = { createWebApp, checkTelegramData };
