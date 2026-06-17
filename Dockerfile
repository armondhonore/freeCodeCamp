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
ENV HOME_LOCATION=https://placeholder.nexlayer.ai
ENV API_LOCATION=https://placeholder.nexlayer.ai/api
ENV FORUM_LOCATION=https://forum.freecodecamp.org
ENV NEWS_LOCATION=https://www.freecodecamp.org/news
ENV RADIO_LOCATION=https://coderadio.freecodecamp.org
ENV STRIPE_PUBLIC_KEY=pk_test_placeholder
ENV PAYPAL_CLIENT_ID=paypal_placeholder
ENV PATREON_CLIENT_ID=patreon_placeholder
ENV GROWTHBOOK_URI=https://cdn.growthbook.io
ENV ALGOLIA_APP_ID=algolia_placeholder_app_id
ENV ALGOLIA_API_KEY=algolia_placeholder_api_key
ENV GATSBY_TELEMETRY_DISABLED=1
ENV GATSBY_CPU_COUNT=2
ENV NODE_OPTIONS="--max-old-space-size=8192"

RUN cd client && pnpm run setup

RUN cd client && pnpm run build

EXPOSE 8000

WORKDIR /app/client

CMD ["pnpm", "run", "serve"]
