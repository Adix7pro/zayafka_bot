#!/usr/bin/env bash
# GitHub'dan yangi kodni olib, botni qayta ishga tushirish
# Ishlatish (serverda):  bash deploy/deploy.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> GitHub'dan yangilanishlar olinmoqda"
git pull --ff-only

echo "==> Kutubxonalar"
npm ci --omit=dev

echo "==> Qayta ishga tushirish"
pm2 startOrReload ecosystem.config.js --update-env
pm2 save

echo "✅ Yangilandi"
pm2 status zayafka_bot
