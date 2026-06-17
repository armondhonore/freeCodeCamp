FROM mirror.gcr.io/library/node:24-alpine

RUN apk add --no-cache python3 make g++ linux-headers git

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY . .

RUN pnpm install --no-frozen-lockfile

# 1. shared: must compile first — challenge-builder and client both import its dist/ exports
RUN pnpm --filter @freecodecamp/shared run build

# 2. browser-scripts: workspace dep of challenge-builder
RUN pnpm --filter @freecodecamp/browser-scripts run build

# 3. challenge-builder: compiles cleanly now that shared dist/ exists
RUN pnpm --filter @freecodecamp/challenge-builder run build

# 4. curriculum setup: compiles TypeScript -> dist/ so its package exports
#    (build-curriculum, file-handler, build-superblock, super-order) resolve
#    when client/utils/build-challenges.js requires them at Gatsby build time
ENV CURRICULUM_LOCALE=english
RUN pnpm --filter @freecodecamp/curriculum run setup

# 5. curriculum build: generates curriculum/generated/curriculum.json which
#    gatsby-source-challenges reads to create GraphQL challenge nodes
RUN pnpm --filter @freecodecamp/curriculum run build

# 6. Client env — required by client/tools/create-env.ts which writes
#    client/config/env.json that gatsby-config.ts imports at build time
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV HOME_LOCATION=https://placeholder.nexlayer.ai
ENV API_LOCATION=https://placeholder.nexlayer.ai/api
ENV FORUM_LOCATION=https://forum.freecodecamp.org
ENV NEWS_LOCATION=https://www.freecodecamp.org/news
ENV RADIO_LOCATION=https://coderadio.freecodecamp.org

# Regenerate schema snapshot instead of validating it — in Docker the
# freshly-built curriculum.json differs from what generated schema.gql,
# so gatsby-plugin-schema-snapshot would abort the webpack phase
ENV GATSBY_UPDATE_SCHEMA_SNAPSHOT=true
ENV GATSBY_TELEMETRY_DISABLED=1
ENV NODE_OPTIONS="--max-old-space-size=7168"

RUN cd client && pnpm run create:env

# 7. Gatsby static site build
RUN cd client && pnpm run build

EXPOSE 8000

WORKDIR /app/client

CMD ["pnpm", "run", "serve"]
