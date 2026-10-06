# Gera o site com Node e serve os arquivos estáticos com nginx.
FROM node:20-alpine AS build
WORKDIR /app
COPY . .
RUN node build.mjs

FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
