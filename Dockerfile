FROM mirror.gcr.io/library/node:22-alpine AS builder
WORKDIR /app
COPY . .
RUN npm install -g pnpm@10.33.3 && pnpm install --no-frozen-lockfile
RUN cd packages/challenge-builder && NODE_OPTIONS="--max-old-space-size=4096" pnpm run build

FROM mirror.gcr.io/library/nginx:alpine
COPY --from=builder /app/packages/challenge-builder/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
