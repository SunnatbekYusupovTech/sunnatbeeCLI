# Aidevix stats backend — ishlab chiqarish image'i (ko'p bosqichli, kichik).
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm install --omit=dev

FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
# Faqat ishlab chiqarish bog'liqliklari + manba kodi.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
# Root foydalanuvchi emas — xavfsizroq.
USER node
EXPOSE 3000
# Konteyner sog'lig'ini /health orqali tekshiramiz.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "src/server.js"]
