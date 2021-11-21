FROM smebberson/alpine-nginx-nodejs
RUN apk add nodejs==16.13.0-r0 -f
RUN nod
# RUN apk add --update nodejs npm
# RUN apk add nodejs==16.13.0-r0 -f
# RUN apk upgrade -f
# ENV PYTHONUNBUFFERED=1
# RUN apk add --update -f --no-cache python3 && ln -sf python3 /usr/bin/python
# RUN python3 -m ensurepip
# RUN pip3 install --no-cache --upgrade pip setuptools

WORKDIR /app

COPY package.json /app
COPY package-lock.json /app

# RUN apk add -f nodejs-npm
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
# CMD export PRODUCTION=true && npm start
# CMD tail -f /dev/null