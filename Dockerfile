
FROM smebberson/alpine-nginx-nodejs
RUN apk add nodejs==16.13.0-r0 -f

WORKDIR /app

COPY package.json /app
COPY package-lock.json /app

RUN npm install -g npm@8.1.4
RUN npm install -g n
RUN n 16.13.0
RUN node -v 
RUN npm i -g "@dasha.ai/cli@latest"
RUN npm install

COPY utils/ /app/utils/
COPY client/ /app/client/
COPY app/ /app/app/
COPY index.js /app/index.js

ADD entrypoint.sh .

EXPOSE 80
EXPOSE 8080
EXPOSE 8000
EXPOSE 1234

COPY nginx.conf /etc/nginx/conf.d/default.conf

CMD ["./entrypoint.sh"]
