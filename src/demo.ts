import {
  Account,
  AccountAddress,
  Aptos,
  AptosConfig,
  Ed25519PrivateKey,
  InputGenerateTransactionPayloadData,
  Network,
} from "@aptos-labs/ts-sdk";
import dotenv from "dotenv";
dotenv.config();

const config = new AptosConfig({
  network: Network.CUSTOM,
  faucet: process.env.FAUCET_URL,
  fullnode: process.env.REST_URL,
});

const aptos = new Aptos(config);

async function main() {
  console.log(`--------- movenow demo --------`);

  // check chain status
  const ledgerInfo = await aptos.getLedgerInfo();
  console.dir({ ledgerInfo }, { depth: null });

  // init user
  const userPrivateKeyHex = process.env.PRIVATE_KEY!;
  const userPrivateKeyBytes = Buffer.from(
    userPrivateKeyHex.slice(2),
    "hex",
  );
  const userPrivateKey = new Ed25519PrivateKey(userPrivateKeyBytes);
  const user = Account.fromPrivateKey({ privateKey: userPrivateKey });
  console.log(`account address: ${user.accountAddress}`);
  const userAddr = user.accountAddress.toString();

  const movenowAddress = process.env.MOVENOW_ADDR!;
  console.log(`movenow contract address: ${movenowAddress}`);

  // create movement
  const createMovementTxn = await aptos.transaction.build.simple({
    sender: user.accountAddress,
    data: {
      function: `${movenowAddress}::movement::create_movement`,
      typeArguments: [],
      functionArguments: [
        'movement name',
        'movement description',
        'movement image',
        100,
      ],
    },
  });
  const committedCreateMovementTxn = await aptos.signAndSubmitTransaction({
    signer: user,
    transaction: createMovementTxn,
  });
  console.log(`create movement txn hash: ${committedCreateMovementTxn.hash}`);
  const sleepTime = 3000;
  await new Promise((r) => setTimeout(r, sleepTime));
  await aptos.waitForTransaction({
    transactionHash: committedCreateMovementTxn.hash,
  });

  // get movements
  const movements = await aptos.view({
    payload: {
      function: `${movenowAddress}::movement::get_movements`,
      functionArguments: [0, 10],
    },
  });
  console.dir({ movements }, { depth: null });

  // mint movement
  const lastMovementId = (movements[0] as any)[0].id;
  const mintMovementTxn = await aptos.transaction.build.simple({
    sender: user.accountAddress,
    data: {
      function: `${movenowAddress}::movement::mint_movement`,
      typeArguments: [],
      functionArguments: [lastMovementId],
    },
  });
  const committedMintMovementTxn = await aptos.signAndSubmitTransaction({
    signer: user,
    transaction: mintMovementTxn,
  });
  console.log(`mint movement txn hash: ${committedMintMovementTxn.hash}`);
  await new Promise((r) => setTimeout(r, sleepTime));
  await aptos.waitForTransaction({
    transactionHash: committedMintMovementTxn.hash,
  });

  // get one movement
  const movement = await aptos.view({
    payload: {
      function: `${movenowAddress}::movement::get_movement`,
      functionArguments: [lastMovementId],
    },
  });
  console.dir({ movement }, { depth: null });

  // get movement owners
  const movementOwners = await aptos.view({
    payload: {
      function: `${movenowAddress}::movement::get_movement_owners`,
      functionArguments: [lastMovementId, 0, 50],
    },
  });
  console.dir({ movementOwners }, { depth: null });

  // get user movements
  const userMovements = await aptos.view({
    payload: {
      function: `${movenowAddress}::movement::get_user_movements`,
      functionArguments: [userAddr],
    },
  });
  console.dir({ userMovements }, { depth: null });
}

main();
