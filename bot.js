const { Telegraf, Markup } = require('telegraf');
const { tgUsers, upsertTgUser, normalizePhone } = require('./db');

// ---------- Matnlar ----------
const texts = {
  uz: {
    askPhone: 'Iltimos, telefon raqamingizni yuboring 👇',
    sendPhoneBtn: '📱 Telefon raqamni yuborish',
    saved: (phone) => `✅ Rahmat! Raqamingiz saqlandi: ${phone}`,
    welcomeBack: (name) => `Xush kelibsiz, ${name}! 👋`,
    notYours: '❗ Iltimos, faqat o‘zingizning raqamingizni tugma orqali yuboring.',
    useButton: '👇 Iltimos, pastdagi tugmani bosing.',
    openApp: '🚀 Ilovani ochish',
    openSite: '🌐 Saytni brauzerda ochish',
    siteInfo: (url) => `🌐 Saytimiz: ${url}`,
  },
  ru: {
    askPhone: 'Пожалуйста, отправьте свой номер телефона 👇',
    sendPhoneBtn: '📱 Отправить номер',
    saved: (phone) => `✅ Спасибо! Ваш номер сохранён: ${phone}`,
    welcomeBack: (name) => `С возвращением, ${name}! 👋`,
    notYours: '❗ Пожалуйста, отправьте свой собственный номер через кнопку.',
    useButton: '👇 Пожалуйста, нажмите кнопку ниже.',
    openApp: '🚀 Открыть приложение',
    openSite: '🌐 Открыть сайт в браузере',
    siteInfo: (url) => `🌐 Наш сайт: ${url}`,
  },
  en: {
    askPhone: 'Please share your phone number 👇',
    sendPhoneBtn: '📱 Share phone number',
    saved: (phone) => `✅ Thanks! Your number has been saved: ${phone}`,
    welcomeBack: (name) => `Welcome back, ${name}! 👋`,
    notYours: '❗ Please share your own number using the button.',
    useButton: '👇 Please press the button below.',
    openApp: '🚀 Open app',
    openSite: '🌐 Open website in browser',
    siteInfo: (url) => `🌐 Our website: ${url}`,
  },
};

function createBot(token, webAppUrl) {
  const bot = new Telegraf(token);
  const users = tgUsers.data;

  const t = (userId) => texts[users[userId]?.lang] || texts.uz;

  const languageKeyboard = Markup.inlineKeyboard([
    [Markup.button.callback('🇺🇿 O‘zbekcha', 'lang_uz')],
    [Markup.button.callback('🇷🇺 Русский', 'lang_ru')],
    [Markup.button.callback('🇬🇧 English', 'lang_en')],
  ]);

  const phoneKeyboard = (userId) =>
    Markup.keyboard([[Markup.button.contactRequest(t(userId).sendPhoneBtn)]])
      .resize()
      .oneTime();

  // Ilova (Telegram ichida) va sayt (oddiy brauzerda) tugmalari — faqat WEBAPP_URL berilgan bo'lsa
  const appKeyboard = (userId) =>
    Markup.inlineKeyboard([
      [Markup.button.webApp(t(userId).openApp, webAppUrl)],
      [Markup.button.url(t(userId).openSite, webAppUrl)],
    ]);

  // Ro'yxatdan o'tgach: pastki klaviaturani olib tashlaymiz va ilova/sayt tugmalarini ko'rsatamiz
  async function sendRegistered(ctx, text) {
    const id = ctx.from.id;
    if (!webAppUrl) return ctx.reply(text, Markup.removeKeyboard());
    await ctx.reply(text, Markup.removeKeyboard());
    await ctx.reply(t(id).siteInfo(webAppUrl), appKeyboard(id));
    // Chap pastdagi "Ilova" tugmasi index.js da hammaga bir marta o'rnatiladi
  }

  // ---------- /start ----------
  bot.start(async (ctx) => {
    const id = ctx.from.id;

    // Allaqachon ro'yxatdan o'tgan bo'lsa
    if (users[id]?.phone) {
      return sendRegistered(ctx, t(id).welcomeBack(ctx.from.first_name));
    }

    await ctx.reply('🌐 Tilni tanlang / Выберите язык / Choose a language:', languageKeyboard);
  });

  // ---------- /sayt — sayt havolasi va tugmalar (ro'yxatdan o'tmaganlarga ham) ----------
  bot.command(['sayt', 'site'], async (ctx) => {
    if (!webAppUrl) return;
    const id = ctx.from.id;
    await ctx.reply(t(id).siteInfo(webAppUrl), appKeyboard(id));
  });

  // ---------- Til tanlash ----------
  bot.action(/^lang_(uz|ru|en)$/, async (ctx) => {
    const id = ctx.from.id;
    upsertTgUser(ctx.from, {
      lang: ctx.match[1],
      step: users[id]?.phone ? 'done' : 'waiting_phone',
    });

    await ctx.answerCbQuery();
    await ctx.deleteMessage().catch(() => {});

    if (users[id].phone) return sendRegistered(ctx, t(id).saved(users[id].phone));
    await ctx.reply(t(id).askPhone, phoneKeyboard(id));
  });

  // ---------- Kontakt qabul qilish ----------
  // Mini App ichida raqam ulashilganda ham Telegram shu yerga kontakt yuboradi
  bot.on('contact', async (ctx) => {
    const id = ctx.from.id;
    const contact = ctx.message.contact;

    // Boshqa odamning kontaktini yuborsa — qabul qilmaymiz
    if (contact.user_id !== id) {
      return ctx.reply(t(id).notYours, phoneKeyboard(id));
    }

    const phone = normalizePhone(contact.phone_number);
    upsertTgUser(ctx.from, {
      lang: users[id]?.lang || 'uz',
      phone,
      step: 'done',
      registered_at: users[id]?.registered_at || new Date().toISOString(),
    });

    await sendRegistered(ctx, t(id).saved(phone));
  });

  // ---------- Raqam kutilayotganda boshqa matn yozsa ----------
  bot.on('text', async (ctx) => {
    const id = ctx.from.id;
    if (users[id]?.step === 'waiting_phone') {
      return ctx.reply(t(id).useButton, phoneKeyboard(id));
    }
  });

  bot.catch((err, ctx) => {
    console.error(`Bot xatoligi (${ctx.updateType}):`, err);
  });

  return bot;
}

module.exports = { createBot };
