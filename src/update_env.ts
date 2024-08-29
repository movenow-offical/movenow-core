import * as fs from 'fs';
import * as yaml from 'yaml';
import * as path from 'path';

// Define the path to the YAML config file
const configFilePath = path.join(__dirname, '..', '.aptos', 'config.yaml');

// Read the YAML file
const fileContents = fs.readFileSync(configFilePath, 'utf8');

// Parse the YAML file
const config = yaml.parse(fileContents);

// Extract the private key and account address
const privateKey = config.profiles.default.private_key;
const accountAddress = config.profiles.default.account;
const restURL = config.profiles.default.rest_url;
const faucetURL = config.profiles.default.faucet_url;

// Define the content for the .env file
const envContent = `MOVENOW_ADDR=0x${accountAddress}\nPRIVATE_KEY=${privateKey}\nREST_URL=${restURL}\nFAUCET_URL=${faucetURL}`;

// Define the path to the .env file
const envFilePath = path.join(__dirname, '..', '.env');

// Write the content to the .env file
fs.writeFileSync(envFilePath, envContent, 'utf8');

console.log('.env file has been created successfully.');
