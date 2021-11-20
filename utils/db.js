const { MongoClient } = require('mongodb');


const credentials = 'X509.pem';

const client = new MongoClient('mongodb+srv://personal-finance-assist.yqigu.mongodb.net/myFirstDatabase?authSource=%24external&authMechanism=MONGODB-X509&retryWrites=true&w=majority', {
  sslKey: credentials,
  sslCert: credentials
});

// Lookup in the collection a client with the given name and secret word.
async function retrieveClientInfo(name, secretWord) {
    await client.connect();
    const database = client.db("personalFinanceAssistant");
    const collection = database.collection("clients");
    return await collection.findOne({"name": name, "secretWord": secretWord});
}

// Create a new client and return the insert result https://mongodb.github.io/node-mongodb-native/4.2/interfaces/InsertOneResult.html
async function createNewClient(info) {
    await client.connect();
    const database = client.db("personalFinanceAssistant");
    const collection = database.collection("clients");
    return await collection.insertOne(info); 
}

// Update a data point for a client with _id as given
async function updateClientData(_id, keyToUpdate, newValue) {
    await client.connect();
    const database = client.db("personalFinanceAssistant");
    const collection = database.collection("clients");
    
    const updateDoc = { $set: {keyToUpdate: newValue}, };

    return await collection.updateOne({"_id": _id}, updateDoc);
}
