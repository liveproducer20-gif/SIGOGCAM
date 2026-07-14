# syntax=docker/dockerfile:1.7
ARG NODE_IMAGE=node:24.18.0-bookworm-slim

FROM ${NODE_IMAGE} AS dependencies
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential python3 unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev \
    && npm cache clean --force

FROM ${NODE_IMAGE} AS runtime
ENV NODE_ENV=production
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl gnupg libgssapi-krb5-2 unixodbc \
    && curl -fsSL https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18 \
    && apt-get purge -y --auto-remove curl gnupg \
    && rm -rf /var/lib/apt/lists/*

COPY --from=dependencies --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json package-lock.json index.js ./
COPY --chown=node:node src ./src

RUN mkdir -p /app/uploads && chown node:node /app/uploads

USER node
EXPOSE 3000
CMD ["node", "index.js"]

FROM runtime AS development
ENV NODE_ENV=development
CMD ["node", "--watch", "index.js"]

FROM runtime AS production
