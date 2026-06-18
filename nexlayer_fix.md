# Nexlayer working build fix

This file is the authoritative, pinned build solution for this repo. Nexlayer uses it verbatim on every run and will not override it. If a future build with this fix fails, Nexlayer appends/updates it rather than regenerating.

## CRITICAL BUILD CONSTRAINTS

**READ BEFORE MODIFYING THE DOCKERFILE BELOW — all of these were discovered through failed builds:**

1. **`COPY . .` MUST come before `RUN pnpm install`** — this is a pnpm monorepo. Every workspace package has its own `package.json` (`client/`, `curriculum/`, `packages/*/`). If only root files (`pnpm-lock.yaml`, `pnpm-workspace.yaml`, `package.json`) are copied before install, pnpm cannot resolve workspace members and install fails with exit status 1. Do NOT split COPY to optimize layer caching.

2. **Do not add `|| true` to any RUN step** — silent failures in upstream packages (shared, challenge-linter, challenge-builder) cause the curriculum and Gatsby builds to fail with cryptic missing-module errors downstream.

3. **Base image must be `mirror.gcr.io/library/node:24` (not slim, not alpine, not 22)** — verified by a successful local build. Slim and alpine variants have caused install failures.

4. **Do not add MongoDB or any second pod** — the Gatsby build produces a static site. There is no runtime database dependency.

5. **CMD must use `serve` package, NOT `gatsby serve`** — `gatsby serve` takes 3-5 minutes to initialize on the built site, causing Nexlayer health checks to time out (checked every ~90s, 3 attempts). The `serve` package (already a devDep of @freecodecamp/client at 13.0.4) starts in under 1 second. Use: `CMD ["node_modules/.bin/serve", "-l", "tcp://0.0.0.0:8000", "public"]`

6. **nexlayer.yaml pod must have `path: /`** — Nexlayer schema requires at least one pod to declare a path. Without it the deploy phase returns `invalid_yaml`.

7. **nexlayer.yaml pod must be named `client`** — do not rename to `app` or any other name.

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

CMD ["node_modules/.bin/serve", "-l", "tcp://0.0.0.0:8000", "public"]
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

Build order (each step depends on the previous):
1. `@freecodecamp/shared` — must go first; challenge-builder and client import its dist/
2. `@freecodecamp/browser-scripts` — dep of challenge-builder
3. `@freecodecamp/challenge-linter` — required by curriculum tsc (lint-localized.ts imports it)
4. `@freecodecamp/challenge-builder` — tsc compile; paths removed from tsconfig so output lands at dist/build.js not dist/challenge-builder/build.js
5. `curriculum run setup` — tsc compiles curriculum to dist/
6. `curriculum run build` — generates curriculum.json (REQUIRED — without this allSuperBlockStructure GraphQL type does not exist and gatsby build fails with error #85923)
7. `rm -rf curriculum/challenges` — removes ~35k raw markdown files before client build; gatsby-source-challenges reads from curriculum.json only, not raw .md files; reduces inotify watch surface
8. `@freecodecamp/client run setup` — runs create:env + create:trending + create:search-placeholder + create:external-curriculum + copy:scripts; must be `setup` not `create:env` — webpack fails without trending.json and search-bar.json
9. `@freecodecamp/client run build` — Gatsby production build; outputs to /app/client/public/
10. `serve -l tcp://0.0.0.0:8000 public` — serves public/ via the `serve` package (devDep of client@13.0.4). Starts in <1s. tcp://0.0.0.0 guarantees all-interface binding for health checks.

Key points — DO NOT change these:
- **CHOKIDAR_USEPOLLING=true + WATCHPACK_POLLING=true** — Docker containers default to 8192 inotify watches. webpack/chokidar exhausts this on the large node_modules tree and fails with ENOSPC. These bypass inotify entirely. NEVER replace with GATSBY_TELEMETRY_DISABLED or other non-watch alternatives.
- **GATSBY_UPDATE_SCHEMA_SNAPSHOT must NOT be set to true** — it skips applying schema.gql types, dropping head/tail GraphQL fields and breaking query extraction.
- **GATSBY_CPU_COUNT=4** — 4 workers for HTML generation across 18k+ pages.
- **Nexlayer seeds HOME_LOCATION, API_LOCATION, STRIPE_PUBLIC_KEY, PAYPAL_CLIENT_ID, PATREON_CLIENT_ID, GROWTHBOOK_URI, ALGOLIA_APP_ID, ALGOLIA_API_KEY from sample env** — do not hardcode here.
