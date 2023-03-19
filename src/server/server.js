import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);


flightSuretyApp.events.OracleRequest({
    fromBlock: 0
  }, function (error, event) {
    if (error) console.log(error)
    console.log(event)
});

const app = express();
app.get('/api', (req, res) => {
    res.send({
      message: 'An API for use with your Dapp!'
    })
})

export default app;


const Web3 = require('web3');
const flightSuretyAppABI = require('./build/contracts/FlightSuretyApp.json').abi;
const flightSuretyOracleABI = require('./build/contracts/FlightSuretyOracle.json').abi;

const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://127.0.0.1:8545'));

const flightSuretyAppAddress = '0x123...'; // Replace with the actual address of the deployed FlightSuretyApp contract
const flightSuretyOracleAddress = '0x456...'; // Replace with the actual address of the deployed FlightSuretyOracle contract

const flightSuretyAppContract = new web3.eth.Contract(flightSuretyAppABI, flightSuretyAppAddress);
const flightSuretyOracleContract = new web3.eth.Contract(flightSuretyOracleABI, flightSuretyOracleAddress);

const oracleIndexes = [1, 2, 3]; // Replace with the indexes assigned to the oracles upon startup

flightSuretyOracleContract.events.OracleRequest({
    fromBlock: 0
}, function(error, event) {
    if (error) console.log(error);
    for (let i = 0; i < oracleIndexes.length; i++) {
        if (oracleIndexes[i] == event.returnValues.index) {
            const statusCode = Math.floor(Math.random() * 6); // Generate a random status code
            flightSuretyOracleContract.methods.submitOracleResponse(oracleIndexes[i], event.returnValues.airline, event.returnValues.flight, event.returnValues.timestamp, statusCode).send({from: web3.eth.accounts[0], gas: 500000});
        }
    }
});
