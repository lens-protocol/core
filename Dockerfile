# syntax=docker/dockerfile:1.3
FROM ethereum/solc:0.8.7 as build-deps

FROM node:16 as build-packages

# Need to be root becuse some issues with hardhat
USER root

COPY package*.json ./
COPY tsconfig*.json ./

RUN npm ci --quiet

FROM node:16

WORKDIR /usr/src/app

COPY --from=build-deps /usr/bin/solc /usr/bin/solc
COPY --from=build-packages /node_modules /node_modules

# Hardhat need permisions to create and remove folders
# We create a new root user because the default generate some issues with the package.
RUN useradd admin && echo "admin:admin" | chpasswd && adduser admin sudo
RUN mkdir /home/admin
RUN chown admin:admin /home/admin

USER admin

