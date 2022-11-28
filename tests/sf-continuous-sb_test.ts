import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v1.0.5/index.ts";
import { assertEquals } from "https://deno.land/std@0.160.0/testing/asserts.ts";

Clarinet.test({
  name: "create-mint-passes should create mint passes",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "create-mint-passes",
        [types.list([types.ascii("This is a metadataURI")])],
        deployer.address
      ),
    ]);

    let [receipt] = block.receipts;
    receipt.result
      .expectOk()
      .expectList()
      .map((mintPass) => mintPass.expectUint(1));

    let lastTokenId = chain.callReadOnlyFn(
      "sf-continuous-sb-v2",
      "get-last-token-id",
      [],
      deployer.address
    );
    lastTokenId.result.expectOk().expectUint(1);
  },
});
Clarinet.test({
  name: "list-in-ustx-should list in the token in market",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
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
        "sf-continuous-sb-v2",
        "list-in-ustx",
        [
          types.uint(1),
          types.uint(1000000),
          types.principal(`${deployer.address}.sf-commission`),
        ],
        deployer.address
      ),
    ]);

    let [receipt] = block.receipts;
    receipt.result.expectOk().expectBool(true);

    let mapItem = chain.callReadOnlyFn(
      "sf-continuous-sb-v2",
      "get-listing-in-ustx",
      [types.uint(1)],
      deployer.address
    );
    let obj = mapItem.result.expectSome().expectTuple();
    obj.commission.expectPrincipal(`${deployer.address}.sf-commission`);
    obj.price.expectUint(1000000);
    obj.royalty.expectUint(500);
  },
});
Clarinet.test({
  name: "burn should not work after listing",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer");
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
        "sf-continuous-sb-v2",
        "list-in-ustx",
        [
          types.uint(1),
          types.uint(1000000),
          types.principal(`${deployer.address}.sf-commission`),
        ],
        deployer.address
      ),
    ]);
    let block = chain.mineBlock([
      Tx.contractCall(
        "sf-continuous-sb-v2",
        "burn",
        [
          types.uint(1)
        ],
        deployer.address
      ),
    ]);
    let [receipt] = block.receipts;
    receipt.result.expectErr().expectUint(115);
  },
});
