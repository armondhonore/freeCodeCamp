FROM mirror.gcr.io/library/node:24-alpine

RUN apk add --no-cache python3 make g++ linux-headers git

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/ packages/
COPY tools/ tools/
COPY api/ api/
COPY client/ client/
COPY curriculum/ curriculum/

RUN pnpm install --no-frozen-lockfile

# Build @freecodecamp/shared first — challenge-builder imports from its dist/
RUN pnpm --filter @freecodecamp/shared run build

# Build browser-scripts — workspace dep of challenge-builder
RUN pnpm --filter @freecodecamp/browser-scripts run build

# Build challenge-builder — now resolves @freecodecamp/shared and browser-scripts
RUN pnpm --filter @freecodecamp/challenge-builder run build

# Required env vars for Gatsby's create-env step (baked into the static bundle)
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV CURRICULUM_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV HOME_LOCATION=https://placeholder.nexlayer.ai
ENV API_LOCATION=https://placeholder.nexlayer.ai/api
ENV NODE_OPTIONS="--max-old-space-size=7168"

RUN cd client && pnpm run create:env

RUN cd client && pnpm run build

EXPOSE 8000

WORKDIR /app/client

CMD ["pnpm", "run", "serve"]
