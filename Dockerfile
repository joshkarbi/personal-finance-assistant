FROM node:latest

WORKDIR /app
COPY package.json /app
COPY package-lock.json /app
COPY index.js /app
COPY X509.pem /app
COPY dasha.pem /app
COPY utils/ /app/utils/
COPY client/ /app/client/
COPY app/ /app/app/

RUN npm install -g npm@8.1.4

RUN npm i -g "@dasha.ai/cli@latest"
RUN cat dasha.pem | dasha account add >&1

RUN npm install
RUN node -v

EXPOSE 8080
EXPOSE 8000
EXPOSE 1234

CMD npm start
# CMD tail -f /dev/null