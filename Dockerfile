ARG PNPM_VERSION=10.33.0

FROM node:24.22.2-alpine@sha256:8a32c8cf649a49915a66e81e7a609223c708d0adabf288ee3f4077d765542f85 AS build

ARG PNPM_VERSION

WORKDIR /build

COPY ["package.json", "pnpm-lock.yaml", "./"]

RUN corepack enable && corepack prepare pnpm@$PNPM_VERSION --activate && pnpm install --frozen-lockfile --silent

COPY . .

RUN pnpm build

FROM node:24.22.2-alpine@sha256:8a32c8cf649a49915a66e81e7a609223c708d0adabf288ee3f4077d765542f85

ARG PNPM_VERSION

LABEL org.opencontainers.image.title="Nostream"
LABEL org.opencontainers.image.source=https://github.com/cameri/nostream
LABEL org.opencontainers.image.description="nostream"
LABEL org.opencontainers.image.authors="Ricardo Arturo Cabral Mejía"
LABEL org.opencontainers.image.licenses=MIT

WORKDIR /app
RUN apk add --no-cache --update git

ADD resources /app/resources

COPY --from=build /build/dist .
COPY --from=build /build/package.json /build/pnpm-lock.yaml ./
COPY --from=build /build/migrations ./migrations
COPY --from=build /build/knexfile.js ./knexfile.js

RUN corepack enable && corepack prepare pnpm@$PNPM_VERSION --activate && pnpm install --prod --frozen-lockfile --silent

USER node:node

CMD ["node", "src/index.js"]

