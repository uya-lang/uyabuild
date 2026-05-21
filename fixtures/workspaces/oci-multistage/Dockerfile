FROM node:20-alpine AS build
WORKDIR /src
COPY app/server.js ./server.js

FROM node:20-alpine
WORKDIR /app
COPY --from=build /src/server.js ./server.js
CMD ["node", "server.js"]
