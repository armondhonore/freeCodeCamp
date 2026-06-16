# Nexlayer Fix

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24-alpine

RUN apk add --no-cache python3 make g++ linux-headers git

WORKDIR /app

RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

COPY . .

RUN pnpm install --no-frozen-lockfile

# Step 1: build @freecodecamp/shared first.
# challenge-builder imports from @freecodecamp/shared/config/challenge-types
# and @freecodecamp/shared/utils/polyvinyl. Without a built dist/ these
# imports cause TS2307 "cannot find module" errors which cascade into every
# implicit-any error in build.ts.
RUN pnpm --filter @freecodecamp/shared run build

# Step 2: build browser-scripts (workspace dep of challenge-builder).
RUN pnpm --filter @freecodecamp/browser-scripts run build

# Step 3: build challenge-builder — now resolves cleanly.
RUN pnpm --filter @freecodecamp/challenge-builder run build

# Step 4: set the env vars Gatsby's create-env step requires at build time.
# HOME_LOCATION / API_LOCATION are baked into the static bundle; update these
# to your actual Nexlayer pod URLs before rebuilding for production.
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV CURRICULUM_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV HOME_LOCATION=https://placeholder.nexlayer.ai
ENV API_LOCATION=https://placeholder.nexlayer.ai/api
ENV NODE_OPTIONS="--max-old-space-size=7168"

# Generates client/config/env.json from the env vars above.
RUN cd client && pnpm run create:env

# Build the Gatsby static site.
RUN cd client && pnpm run build

EXPOSE 8000

WORKDIR /app/client

# gatsby serve -p 8000 (defined in client/package.json scripts.serve)
CMD ["pnpm", "run", "serve"]
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
    - name: api
      image: "# filled by pipeline"
      servicePorts:
        - 3000
      vars:
        PORT: "3000"
        MONGOHQ_URL: "mongodb://${mongodb:27017}/freecodecamp"
    - name: mongodb
      image: mirror.gcr.io/library/mongo:7
      servicePorts:
        - 27017
```

## Notes

**What was wrong with the previous Dockerfile:**

The build attempted `cd packages/challenge-builder && pnpm run build` (which runs `tsc`) before the `@freecodecamp/shared` workspace package had been compiled to its `dist/` directory. `challenge-builder` imports:

```ts
import { challengeTypes } from '@freecodecamp/shared/config/challenge-types';
import type { ChallengeFile } from '@freecodecamp/shared/utils/polyvinyl';
```

These resolve through the `exports` map in `packages/shared/package.json` to `dist/config/challenge-types.mjs` and `dist/utils/polyvinyl.mjs` — files that don't exist until `pnpm --filter @freecodecamp/shared run build` (which runs `tsdown`) has executed. With no `dist/`, TypeScript emits TS2307 for both imports. Every variable that depended on the missing `ChallengeFile` type then became implicit `any`, producing the TS7031/TS7006 errors at lines 240, 281, 289, and 315.

The same root cause applied to `@freecodecamp/browser-scripts`, which is also a workspace dep of `challenge-builder` and must be built before `tsc` runs.

**Port correction in nexlayer.yaml:**

The original yaml had `client` on port 3000 and `api` on port 8000. The actual defaults are the opposite:
- Gatsby serves the built client via `gatsby serve -p 8000` (hardcoded in `client/package.json` `scripts.serve`)
- Fastify API defaults to `process.env.PORT || '3000'` (`api/src/utils/env.ts:187`)

**Build-time URL limitation:**

Gatsby bakes `HOME_LOCATION` and `API_LOCATION` into the static bundle at build time (via `client/tools/create-env.ts` → `client/config/env.json`). For a real Nexlayer deployment, rebuild the image after setting these to the actual pod URLs. The runtime `vars` entries in nexlayer.yaml are available to Node processes (e.g. the API) but cannot retroactively change a pre-built Gatsby bundle.
