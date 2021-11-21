const dasha = require("@dasha.ai/sdk");
const { v4: uuidv4 } = require("uuid");
const express = require("express");
const cors = require("cors");
const wslib = require('ws');
const dbUtils = require('./utils/db');

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
const { ObjectId } = require("mongodb");

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

  

  app.setExternal("canGoToPlace", async(argv, conv) => {
    var url = "https://maps.googleapis.com/maps/api/place/textsearch/json?query=" + argv.place + "+london+canada&fields=price_level&key=AIzaSyAQsvP2FK1CoeyzhXdL0vPDJ06tfsdXLZw";
    const res = await axios.get(url);
    var priceLevel = res.data.results[0].price_level;
    res.data

    var avgSpend = {1: 15, 2: 25, 3: 50, 4: 100}

    var expectedSpend = avgSpend[priceLevel]

    if (expectedSpend < 25)
    {
      await sendToFrontendOverWS("Can afford to go to place.");
      return true;
    }
    else 
    {
      await sendToFrontendOverWS("Cannot afford to go to place.");
      return false; 
    }
  });
  app.setExternal("calculateMonthlySavings", async(argv, conv) => {
    // assuming 78% take-home salary rate
    var monthlySavings = (parseInt(argv.salary) * 0.78) / 12 - parseInt(argv.monthlySpend);
    return monthlySavings.toString();
  })

  app.setExternal("calculateMonthsToGoal", async(argv, conv) => {
    var monthsToGoal = (parseInt(argv.goalAmount) - (parseInt(argv.investments) + parseInt(argv.cash))) / parseInt(argv.monthlySavings);
    return Math.round(monthsToGoal);
  })

  app.setExternal("confirm", async(args, conv) => {
    var clientInfo = await dbUtils.retrieveClientInfo(args.secretWord);
    console.log("CLIENT INFO", clientInfo);
    if (clientInfo == null)
    {
      return false;
    }
    else
    {
      return true;
    }
  });

  app.setExternal("getClientName", async(args, conv) => {
    var clientInfo = await dbUtils.retrieveClientInfo(args.secretWord);
    return clientInfo.name;
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
// const test = async() => {
//   var clientInfo = await dbUtils.retrieveClientInfo("bananas");
//   console.log(clientInfo);
//   await dbUtils.updateClientSecretWord(new ObjectId("619983efaae1fe493b863481"),"banana");
//   clientInfo = await dbUtils.retrieveClientInfo("banana");
//   console.log(clientInfo);
// };

// test()
