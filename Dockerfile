FROM node:16 as pnpm
MAINTAINER Bruno Perel

RUN npm i -g pnpm

FROM pnpm AS app-install
MAINTAINER Bruno Perel

RUN apt-get update \
 && apt-get install --no-install-recommends -y git ca-certificates build-essential g++ python3 fontconfig \
 && apt-get clean \

WORKDIR /app
COPY package.json pnpm-lock.yaml .eslintrc.js ./
RUN pnpm i

WORKDIR /home
COPY prisma server/package*.json ./
RUN pnpm i

FROM pnpm AS install-nuxt

RUN apt-get update \
 && apt-get install --no-install-recommends -y git ca-certificates build-essential g++ python3 fontconfig \
 && apt-get clean

WORKDIR /home
COPY prisma package*.json ./
RUN pnpm i
RUN ./node_modules/.bin/prisma generate

FROM node:16-slim AS runtime-nuxt

ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

WORKDIR /usr/src/nuxt-app

RUN apt-get update \
 && apt-get install --no-install-recommends -y openssl python3 \
 && apt-get clean

COPY . ./
COPY .env.prod ./.env
COPY --from=install-nuxt /home/node_modules ./node_modules

RUN rm -rf server && pnpm run build

EXPOSE 3000

ENTRYPOINT [ "node_modules/.bin/nuxt", "start" ]

FROM pnpm AS runtime-socketio

WORKDIR /home

RUN apt-get update \
 && apt-get install --no-install-recommends -y openssl \
 && apt-get clean

COPY .env.prod .env
COPY server ./server
COPY types ./types

WORKDIR /home/server
COPY --from=install-socketio /home/node_modules ./node_modules
COPY --from=install-nuxt /home/node_modules/.prisma ./node_modules/.prisma
RUN pnpm i typescript

EXPOSE 4000

ENTRYPOINT [ "./node_modules/.bin/ts-node", "index.ts" ]
