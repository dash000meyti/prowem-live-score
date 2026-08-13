FROM nginx:1.27-alpine

COPY docker/nginx/production.conf /etc/nginx/conf.d/default.conf
COPY public /var/www/html/public

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=5 \
    CMD wget -q --spider http://127.0.0.1/up || exit 1
