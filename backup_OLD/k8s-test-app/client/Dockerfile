FROM node:alpine as react-build
RUN mkdir -p /app
WORKDIR /app
copy . /app
RUN npm install
RUN npm run build

FROM nginx:alpine
#FROM nginxinc/nginx-unprivileged:stable-alpine
RUN adduser -D --uid 1001 -g appuser appuser
COPY --from=react-build /app/build /usr/share/nginx/html
COPY template /template
COPY nginx.conf /etc/nginx/nginx.conf
WORKDIR /template
RUN touch /var/run/nginx.pid && \
  chown -R appuser:0 /var/run/nginx.pid && \
  chown -R appuser:0 /var/cache/nginx && \
  chown -R appuser:0 /etc/nginx/conf.d/
USER appuser

EXPOSE 3000
#CMD ["nginx", "-g", "daemon off;"]
CMD ["sh", "init-nginx.sh"]
