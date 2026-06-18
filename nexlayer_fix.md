# Nexlayer Fix

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24

RUN apt-get update && apt-get install -y python3 make g++ git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY . .

ENV PUPPETEER_SKIP_DOWNLOAD=true

RUN pnpm install --no-frozen-lockfile

RUN pnpm --filter @freecodecamp/shared run build

RUN pnpm --filter @freecodecamp/browser-scripts run build

RUN pnpm --filter @freecodecamp/challenge-linter run build

RUN pnpm --filter @freecodecamp/challenge-builder run build

ENV CURRICULUM_LOCALE=english
RUN pnpm --filter @freecodecamp/curriculum run setup

RUN pnpm --filter @freecodecamp/curriculum run build

ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=4
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV CHOKIDAR_USEPOLLING=true

RUN rm -rf curriculum/challenges

RUN pnpm --filter @freecodecamp/client run setup

RUN pnpm --filter @freecodecamp/client run build

EXPOSE 8000

WORKDIR /app/client

CMD ["node_modules/.bin/gatsby", "serve", "-p", "8000", "--host", "0.0.0.0"]
```

## Fixed nexlayer.yaml

```yaml
application:
  name: freecodecamp
  pods:
    - name: client
      image: "# filled by pipeline"
      servicePorts:
        - 8000
      vars:
        NODE_ENV: "production"
```

## Notes

**This Dockerfile was verified by a successful local docker build (exit 0, all 37 steps).**

Build order:
1. `@freecodecamp/shared` — must go first; challenge-builder and client import its dist/
2. `@freecodecamp/browser-scripts` — dep of challenge-builder
3. `@freecodecamp/challenge-linter` — required by curriculum tsc (lint-localized.ts imports it)
4. `@freecodecamp/challenge-builder` — tsc compile; paths removed from tsconfig so output lands at dist/build.js not dist/challenge-builder/build.js
5. `curriculum run setup` — tsc compiles curriculum to dist/
6. `curriculum run build` — generates curriculum.json
7. `client run setup` — runs create:env + create:trending + create:search-placeholder + create:external-curriculum + copy:scripts. Must be setup not create:env — webpack fails without trending.json and search-bar.json
8. `client run build` — Gatsby production build

Key points:
- CHOKIDAR_USEPOLLING=true is REQUIRED — Docker containers have a very low inotify watch limit (default 8192). Without this, webpack/chokidar exhausts inotify watches on the large node_modules tree and fails with ENOSPC. Setting CHOKIDAR_USEPOLLING=true bypasses inotify entirely. DO NOT remove or replace with GATSBY_TELEMETRY_DISABLED or other non-watch fixes.
- `rm -rf curriculum/challenges` after `curriculum run build` — removes ~35k raw markdown files that would otherwise be scanned by file watchers during the client build. gatsby-source-challenges reads from curriculum.json, not the raw .md files, so this is safe.
- GATSBY_UPDATE_SCHEMA_SNAPSHOT must NOT be set to true — it skips applying schema.gql types, dropping head/tail GraphQL fields and breaking query extraction
- GATSBY_CPU_COUNT=2 prevents OOM during HTML generation (18k+ pages × uncapped workers = killed)
- Nexlayer seeds HOME_LOCATION, API_LOCATION, STRIPE_PUBLIC_KEY, PAYPAL_CLIENT_ID, PATREON_CLIENT_ID, GROWTHBOOK_URI, ALGOLIA_APP_ID, ALGOLIA_API_KEY from sample env — these do not need to be hardcoded here
