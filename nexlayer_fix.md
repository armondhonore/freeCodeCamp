# Nexlayer working build fix

This file is the authoritative, pinned build solution for this repo. Nexlayer uses it verbatim on every run and will not override it. If a future build with this fix fails, Nexlayer appends/updates it rather than regenerating.

## Fixed Dockerfile

```dockerfile
FROM mirror.gcr.io/library/node:24-slim

# Install native build tools
RUN apt-get update && apt-get install -y python3 make g++ git ca-certificates unzip tar && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Use corepack for pnpm 10 as per packageManager
RUN npm i -g corepack@latest && corepack enable && corepack prepare pnpm@10.33.3 --activate

# Copy all files first. In a pnpm monorepo with complex internal dependencies 
# and potential dynamic package discovery, copying the whole repo prevents 
# "workspace package not found" errors during install.
COPY . .

# Install dependencies
RUN pnpm install --no-frozen-lockfile

# Build-time Environment Variables
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV CURRICULUM_LOCALE=english
ENV FREECODECAMP_NODE_ENV=production
ENV DEPLOYMENT_ENV=staging
ENV CLIENT_LOCALE=english
ENV SHOW_UPCOMING_CHANGES=false
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=2
ENV NODE_OPTIONS="--max-old-space-size=8192"

# To prevent ENOSPC (System limit for number of file watchers reached) during Gatsby build,
# we set the Chokidar polling environment variable.
ENV CHOKIDAR_USEPOLLING=true

# Build internal packages in the order required by dependencies
# 1. Shared utilities
RUN pnpm --filter @freecodecamp/shared run build
# 2. Browser scripts (required by challenge-builder and client)
RUN pnpm --filter @freecodecamp/browser-scripts run build
# 3. Linter and Builder
RUN pnpm --filter @freecodecamp/challenge-linter run build
RUN pnpm --filter @freecodecamp/challenge-builder run build

# Setup and Build Curriculum (generates curriculum.json)
RUN pnpm --filter @freecodecamp/curriculum run setup
RUN pnpm --filter @freecodecamp/curriculum run build

# Setup and Build Client (Gatsby)
# We run setup and build in the client directory
RUN cd client && pnpm run setup
RUN cd client && pnpm run build

# Final Runtime Configuration
EXPOSE 8000
WORKDIR /app/client

# Use gatsby serve to host the static site
CMD ["node_modules/.bin/gatsby", "serve", "-p", "8000", "--host", "0.0.0.0"]
```
