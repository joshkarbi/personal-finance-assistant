FROM node:latest

WORKDIR /app

ARG MONGODB_CREDS
ARG DASHA_APIKEY

RUN echo $MONGODB_CREDS

RUN echo $MONGODB_CREDS > X509.pem
RUN echo $DASHA_APIKEY > .dasha
RUN cat X509.pem
RUN cat .dasha

COPY package.json /app
COPY package-lock.json /app

RUN npm install -g npm@8.1.4

RUN npm i -g "@dasha.ai/cli@latest"
RUN npm install

COPY .dasha /app
COPY dasha.pem /app
COPY utils/ /app/utils/
COPY client/ /app/client/
COPY app/ /app/app/



EXPOSE 8080
EXPOSE 8000
EXPOSE 1234

CMD npm start
# CMD tail -f /dev/null