FROM nginx:latest

# Copiar contenido web
COPY ./contenido-web /usr/share/nginx/html

# Copiar certificados
COPY ./certificados/nginx.crt /etc/nginx/ssl/nginx.crt
COPY ./certificados/nginx.key /etc/nginx/ssl/nginx.key

# Copiar archivo htpasswd
COPY ./htpasswd/.htpasswd /etc/nginx/.htpasswd

# Copiar configuración de Nginx
COPY ./nginx.conf /etc/nginx/conf.d/default.conf

# Exponer puertos
EXPOSE 80 443