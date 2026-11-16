# The dx.server image. CI builds it on every push and tags it with the commit
# SHA; infra.dx runs it. Build it locally with `make build`.

# ---- rawgraphs-charts, which the chart renderer imports ----------------------
FROM node:22.21-alpine3.21 AS charts
RUN apk add --no-cache git
# The rawgraphs-charts commit the charts are rendered with (on feat/DX-137; the
# client's Dockerfile pins the same one). `make charts` builds the same one too.
ARG RAWGRAPHS_REPO=https://github.com/zimmerman-team/rawgraphs-charts.git
ARG RAWGRAPHS_REF=17c017a71ee3c95944d2911f072b3e3c818f6e32
WORKDIR /charts
RUN git init -q \
 && git remote add origin "$RAWGRAPHS_REPO" \
 && git fetch -q --depth 1 origin "$RAWGRAPHS_REF" \
 && git checkout -q FETCH_HEAD
# Build lib/ with rollup only (rawgraphs' own `yarn build` also copies itself
# into sibling folders), then keep only the dependencies lib/ imports at runtime.
RUN yarn install --frozen-lockfile --network-timeout 600000 \
 && npx rollup -c \
 && yarn install --production --frozen-lockfile --ignore-scripts --network-timeout 600000

# ---- the server -------------------------------------------------------------
FROM node:22.21-alpine3.21
WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

COPY . .
RUN yarn build

# src/utils/renderChart.ts imports ../../rawgraphs-charts/lib, next to src/ and dist/.
COPY --from=charts /charts/package.json rawgraphs-charts/package.json
COPY --from=charts /charts/lib rawgraphs-charts/lib
COPY --from=charts /charts/node_modules rawgraphs-charts/node_modules
RUN mkdir -p logging

ENV NODE_ENV=production
EXPOSE 4200
# Migrations run when the server boots; `make migrate` runs them on their own.
CMD ["node", "-r", "source-map-support/register", "."]
