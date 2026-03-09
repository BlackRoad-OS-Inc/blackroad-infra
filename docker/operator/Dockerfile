# Copyright (c) 2025-2026 BlackRoad OS, Inc. All Rights Reserved.
FROM node:22-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --ignore-scripts
COPY . .
RUN npm run build
RUN npm link
ENTRYPOINT ["br"]
