
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';


Clarinet.test({
  name: "Mint continuous nft and place bid",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get('deployer')!;
    let wallet_1 = accounts.get('wallet_1')!;
    let block = chain.mineBlock([
      Tx.contractCall('sf-continuous', 'claim', [
        types.list([
          types.ascii("https://sf.io/first-continous-token")
        ])
      ], deployer.address)
    ]);
    assertEquals(block.height, 2);
    // console.log("block", block);


    block = chain.mineBlock([
      Tx.contractCall('sf-marketplace-bid', 'place-bid', [
        types.principal(deployer.address + '.sf-continuous'),
        types.some(types.uint(1)),
        types.uint(10000000),
        types.uint(3),
        types.some(types.ascii("first bid"))
      ], 
      wallet_1.address)
    ]);
    assertEquals(block.height, 3);
    console.log("block", block);

  },
});
