FROM node:20-alpine

WORKDIR /app

# Copy server files and compiled Flutter web build
COPY package.json ./
COPY server.js ./
COPY build/web ./build/web

ENV PORT=3000
EXPOSE 3000

CMD ["node", "server.js"]
