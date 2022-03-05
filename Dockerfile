# syntax=docker/dockerfile:1.3
FROM ethereum/solc:0.8.7 as build-deps

FROM node:16 as build-packages

COPY package*.json ./
COPY tsconfig*.json ./

RUN npm ci --quiet

FROM node:16

WORKDIR /src

COPY --from=build-deps /usr/bin/solc /usr/bin/solc
COPY --from=build-packages /node_modules /node_modules
COPY docker-entrypoint.sh /docker-entrypoint.sh

USER node

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]