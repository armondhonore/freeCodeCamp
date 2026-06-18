# Nexlayer working build fix

This file is the authoritative, pinned build solution for this repo. Nexlayer uses it verbatim on every run and will not override it. If a future build with this fix fails, Nexlayer appends/updates it rather than regenerating.

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24-slim

# Install native build tools and essential utilities
RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use corepack for pnpm 10 as per packageManager field
RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

# CRITICAL FIX: Copy the entire repository before pnpm install.
# The error ERR_PNPM_WORKSPACE_PKG_NOT_FOUND occurs because pnpm needs to see
# the package.json files of all workspace members (like @freecodecamp/eslint-config)
# to resolve workspace:* dependencies during the install phase.
COPY . .

# Install dependencies
RUN pnpm install --no-frozen-lockfile

# Skip puppeteer's Chrome download
ENV PUPPETEER_SKIP_DOWNLOAD=true

# Build the shared packages and tools in order
RUN pnpm --filter @freecodecamp/shared run build
RUN pnpm --filter @freecodecamp/browser-scripts run build
RUN pnpm --filter @freecodecamp/challenge-linter run build
RUN pnpm --filter @freecodecamp/challenge-builder run build

# Build curriculum
# Added CHOKIDAR_USEPOLLING=true to prevent ENOSPC (too many file watchers) during build
ENV CHOKIDAR_USEPOLLING=true
ENV CURRICULUM_LOCALE=english
RUN pnpm --filter @freecodecamp/curriculum run setup
RUN pnpm --filter @freecodecamp/curriculum run build

# Build the Gatsby client
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=2
ENV NODE_OPTIONS="--max-old-space-size=8192"

WORKDIR /app/client
RUN pnpm run setup
RUN pnpm run build

EXPOSE 8000

CMD ["node_modules/.bin/gatsby", "serve", "-p", "8000", "--host", "0.0.0.0"]
```
