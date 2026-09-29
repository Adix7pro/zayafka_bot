const fs = require('fs');
const path = require('path');

// Ma'lumotlar data/ papkasida saqlanadi (git'ga qo'shilmaydi)
const DATA_DIR = path.join(__dirname, 'data');
fs.mkdirSync(DATA_DIR, { recursive: true });

// Oddiy JSON "baza". Bot va sayt bitta jarayonda ishlaydi,
// shuning uchun ikkalasi ham shu obyektlarni ishlatadi.
function createStore(file) {
  const filePath = path.join(DATA_DIR, file);
  let data;
  try {
    data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    data = {};
  }

  return {
    data,
    save() {
      // Avval vaqtinchalik faylga yozib, keyin almashtiramiz — fayl buzilib qolmasligi uchun
      const tmp = filePath + '.tmp';
      fs.writeFileSync(tmp, JSON.stringify(data, null, 2));
      fs.renameSync(tmp, filePath);
    },
  };
}

// Telegram foydalanuvchilari (bot va Mini App) — Telegram ID bo'yicha
const tgUsers = createStore('users.json');
// Oddiy saytdan kelganlar — telefon raqam bo'yicha
const webUsers = createStore('web_users.json');

function upsertTgUser(from, fields) {
  const prev = tgUsers.data[from.id] || {};
  tgUsers.data[from.id] = {
    ...prev,
    id: from.id,
    first_name: from.first_name,
    username: from.username || null,
    ...fields,
  };
  tgUsers.save();
  return tgUsers.data[from.id];
}

function normalizePhone(phone) {
  const digits = String(phone || '').replace(/\D/g, '');
  if (digits.length < 9 || digits.length > 15) return null;
  return '+' + digits;
}

module.exports = { tgUsers, webUsers, upsertTgUser, normalizePhone };
