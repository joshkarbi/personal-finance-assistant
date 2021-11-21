# personal-finance-assistant
A personal finance assistant built with DashaAI.

## How to start the app

1. Login to dasha account via `npx dasha account login`
2. Make `npm i` to install dependencies
3. Make `export DASHA_APIKEY=<your key> && npm start` to run dasha application on nodejs server and launch a web application that will communicate with the server via rest api
5. Open `http://localhost:1234/` and click to Start button for run call

## Connect to MongoDB Cluster ##
```bash
mongosh "mongodb+srv://personal-finance-assist.yqigu.mongodb.net/myFirstDatabase?authSource=%24external&authMechanism=MONGODB-X509" --tls --tlsCertificateKeyFile X509.pem
```