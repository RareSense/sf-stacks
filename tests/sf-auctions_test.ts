import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v1.0.5/index.ts";
import { assertEquals } from "https://deno.land/std@0.160.0/testing/asserts.ts";

Clarinet.test({
  name: "it should place a bid on a mint-pass",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let wallet_1 = accounts.get("wallet_1");
    chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "create-mint-passes",
        [types.list([types.ascii("This is a metadataURI")])],
        deployer.address
      ),
    ]);
    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_1.address
      ),
    ]);

    let [receipt] = block.receipts;
    receipt.result.expectOk().expectAscii("Bid placed");
  },
});
Clarinet.test({
  name: "Bid should be greater than previous bid by at least 1 stx",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let wallet_1 = accounts.get("wallet_1");
    let wallet_2 = accounts.get("wallet_2");
    chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "create-mint-passes",
        [types.list([types.ascii("This is a metadataURI")])],
        deployer.address
      ),
    ]);
    chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_1.address
      ),
    ]);
    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1999999),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_2.address
      ),
    ]);

    let [receipt] = block.receipts;
    receipt.result.expectErr().expectUint(111);
  },
});
Clarinet.test({
  name: "It should place multiple bids",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let wallet_1 = accounts.get("wallet_1");
    let wallet_2 = accounts.get("wallet_2");
    chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "create-mint-passes",
        [types.list([types.ascii("This is a metadataURI")])],
        deployer.address
      ),
    ]);
    chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_1.address
      ),
    ]);
    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(2000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_2.address
      ),
    ]);

    let [receipt] = block.receipts;
    receipt.result.expectOk().expectAscii("Bid placed");
  },
});
Clarinet.test({
  name: "it should not place a bid if nft doesn't exist",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let wallet_1 = accounts.get("wallet_1");

    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_1.address
      ),
    ]);

    let [receipt] = block.receipts;
    console.log(block.receipts)
    // receipt.result.expectErr().expectUint(101);

  },
});
Clarinet.test({
  name: "it should accept a bid on a mint-pass",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let wallet_1 = accounts.get("wallet_1");
    chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "create-mint-passes",
        [types.list([types.ascii("This is a metadataURI")])],
        deployer.address
      ),
    ]);
    chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "place-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
          types.uint(1000000),
          types.some(types.ascii("This is a memo")),
        ],
        wallet_1.address
      ),
    ]);

    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-auctions",
        "accept-bid",
        [
          types.principal(`${deployer.address}.sf-continuous-sb-v2`),
          types.uint(1),
        ],
        deployer.address
      ),
    ]);
    let [receipt] = block.receipts;
    receipt.result.expectOk().expectBool(true);

    let token = chain.callReadOnlyFn(
      "sf-continuous-sb-v2",
      "get-owner",
      [types.uint(1)],
      wallet_1.address
    );
    token.result.expectOk().expectSome().expectPrincipal(wallet_1.address);
  },
});
