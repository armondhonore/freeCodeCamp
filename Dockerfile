FROM mirror.gcr.io/library/node:24-alpine

RUN apk add --no-cache python3 make g++ linux-headers git

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY . .

RUN pnpm install --no-frozen-lockfile

# 1. shared must be built first — challenge-builder imports its dist/ exports
RUN pnpm --filter @freecodecamp/shared run build

# 2. browser-scripts — workspace dep of challenge-builder
RUN pnpm --filter @freecodecamp/browser-scripts run build

# 3. challenge-builder — resolves cleanly now that shared dist/ exists
RUN pnpm --filter @freecodecamp/challenge-builder run build

# 4. curriculum setup — compiles TS to dist/ so its exports (build-curriculum,
#    file-handler, etc.) are available; client/utils/build-challenges.js requires them
RUN pnpm --filter @freecodecamp/curriculum run setup

# 5. curriculum build — generates curriculum/generated/curriculum.json that
#    gatsby-source-challenges reads at Gatsby build time
ENV CURRICULUM_LOCALE=english
RUN pnpm --filter @freecodecamp/curriculum run build

# 6. Env vars baked into the Gatsby static bundle via client/tools/create-env.ts
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV HOME_LOCATION=https://placeholder.nexlayer.ai
ENV API_LOCATION=https://placeholder.nexlayer.ai/api
ENV NODE_OPTIONS="--max-old-space-size=7168"

RUN cd client && pnpm run create:env

# 7. Gatsby build
RUN cd client && pnpm run build

EXPOSE 8000

WORKDIR /app/client

CMD ["pnpm", "run", "serve"]
