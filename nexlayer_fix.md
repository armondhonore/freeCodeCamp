# Nexlayer Fix

This file is the authoritative, pinned build solution for this repo.

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24

RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

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
ENV WATCHPACK_POLLING=true

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
  name: bold-lake-freecodecamp
  pods:
    - name: client
      image: "# filled by pipeline"
      path: /
      servicePorts:
        - 8000
      vars:
        NODE_ENV: "production"
```

## Notes

**This Dockerfile was verified by a successful local docker build (exit 0) with HTTP 200 confirmed.**

Build order:
1. `@freecodecamp/shared` — must go first; challenge-builder and client import its dist/
2. `@freecodecamp/browser-scripts` — dep of challenge-builder
3. `@freecodecamp/challenge-linter` — required by curriculum tsc (lint-localized.ts imports it)
4. `@freecodecamp/challenge-builder` — tsc compile; paths removed from tsconfig so output lands at dist/build.js not dist/challenge-builder/build.js
5. `curriculum run setup` — tsc compiles curriculum to dist/
6. `curriculum run build` — generates curriculum.json (REQUIRED — without this allSuperBlockStructure GraphQL type does not exist and gatsby build fails with #85923)
7. `rm -rf curriculum/challenges` — removes ~35k raw markdown files before client build; gatsby-source-challenges reads from curriculum.json only, not raw .md files; reduces inotify watch surface
8. `@freecodecamp/client run setup` — runs create:env + create:trending + create:search-placeholder + create:external-curriculum + copy:scripts; must be setup not create:env — webpack fails without trending.json and search-bar.json
9. `@freecodecamp/client run build` — Gatsby production build

Key points — DO NOT change these without understanding why:
- **CHOKIDAR_USEPOLLING=true + WATCHPACK_POLLING=true** — Docker containers have a very low inotify watch limit (default 8192). Without these, webpack/chokidar exhausts inotify watches on the large node_modules tree and fails with ENOSPC. These bypass inotify entirely. NEVER replace with GATSBY_TELEMETRY_DISABLED or "non-watch" alternatives.
- **node:24 base image** — locally verified. Do NOT downgrade to node:22-slim or alpine.
- **No `|| true` on build steps** — silent failures in shared/linter/builder packages break the curriculum and client builds downstream. All steps must succeed.
- **GATSBY_UPDATE_SCHEMA_SNAPSHOT must NOT be set to true** — it skips applying schema.gql types, dropping head/tail GraphQL fields and breaking query extraction.
- **GATSBY_CPU_COUNT=4** — 4 workers for HTML generation across 18k+ pages. Lower values (1-2) work but are slow; higher values risk OOM if container RAM is limited.
- **Single pod (client only)** — this is a static Gatsby site. No MongoDB or API pod is needed for the client deployment.
- **Nexlayer seeds HOME_LOCATION, API_LOCATION, STRIPE_PUBLIC_KEY, PAYPAL_CLIENT_ID, PATREON_CLIENT_ID, GROWTHBOOK_URI, ALGOLIA_APP_ID, ALGOLIA_API_KEY from sample env** — these do not need to be hardcoded here.
