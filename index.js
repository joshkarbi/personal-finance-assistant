const dasha = require("@dasha.ai/sdk");
const { v4: uuidv4 } = require("uuid");
const express = require("express");
const cors = require("cors");
const wslib = require('ws');


const expressApp = express();
expressApp.use(express.json());
expressApp.use(cors());

const wss = new wslib.WebSocketServer({ port: 8080 });

wss.on('connection', function connection(ws) {
  ws.on('message', function incoming(message) {
    console.log('received: %s', message);
  });

  ws.send('Connected!');
});

const axios = require("axios").default;

async function sendToFrontendOverWS(message) {
  wss.clients.forEach(function each(client) {
    if (client.readyState === wslib.WebSocket.OPEN) {
      client.send(message);
    }
  });
}

const main = async () => {
  const app = await dasha.deploy(`${__dirname}/app`);

  app.setExternal("canAffordExpense", async(argv, conv) => {
    if (parseInt(argv.cost) < 100)
    {
      await sendToFrontendOverWS("Can afford expense.");
      return true;
    }
    else 
    {
      await sendToFrontendOverWS("Cannot afford expense.");
      return false; 
    }
  });

  app.setExternal("confirm", async(args, conv) => {
      console.log("collected fruit is " + args.fruit);

      const res = await axios.post( "http://ptsv2.com/t/dasha-test/post");
      console.log(" JSON data from API ==>", res.data);

      const receivedFruit = res.data.favoriteFruit;
      console.log("fruit is  ==>", receivedFruit);

    if (args.fruit == receivedFruit)
      return true;
    else 
      return false; 
  });

// External function check status 
  app.setExternal("status", async(args, conv) => {

    const res = await axios.post( "http://ptsv2.com/t/dasha-test/post");
    console.log(" JSON data from API ==>", res.data);

    const receivedFruit = res.data.favoriteFruit;
    console.log("status is  ==>", res.data.status);

    if (res.data.status = "approved")
    return("Congratulations Mr. Coyote. Your application is approved. You can now buy anything you like at the desert ACME shop by the big cactus."); 
    else 
    return("Apologies Mr. Coyote. Your application is not approved. ");
  });

  await app.start({ concurrency: 10 });

  expressApp.get("/sip", async (req, res) => {
    const domain = app.account.server.replace("app.", "sip.");
    const endpoint = `wss://${domain}/sip/connect`;

    // client sip address should:
    // 1. start with `sip:reg`
    // 2.  be unique
    // 3. use the domain as the sip server
    const aor = `sip:reg-${uuidv4()}@${domain}`;

    res.send({ aor, endpoint });
  });

  expressApp.post("/call", async (req, res) => {
    const { aor, name } = req.body;
    res.sendStatus(200);

    console.log("Start call for", req.body);
    const conv = app.createConversation({ endpoint: aor, name });
    conv.on("transcription", console.log);
    conv.audio.tts = "dasha";
    conv.audio.noiseVolume = 0;

    await conv.execute();
  });

  const server = expressApp.listen(8000, () => {
    console.log("Api started on port 8000.");
  });

  process.on("SIGINT", () => server.close());
  server.once("close", async () => {
    await app.stop();
    app.dispose();
  });
};

main();
