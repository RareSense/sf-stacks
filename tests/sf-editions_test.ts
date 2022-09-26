
import { Clarinet, Tx, Chain, Account, Contract, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// Clarinet.test({
//     name: "Ensure that <...>",
//     async fn(chain: Chain, accounts: Map<string, Account>) {
//         let block = chain.mineBlock([
//             /* 
//              * Add transactions with: 
//              * Tx.contractCall(...)
//             */
//         ]);
//         assertEquals(block.receipts.length, 0);
//         assertEquals(block.height, 2);

//         block = chain.mineBlock([
//             /* 
//              * Add transactions with: 
//              * Tx.contractCall(...)
//             */
//         ]);
//         assertEquals(block.receipts.length, 0);
//         assertEquals(block.height, 3);
//     },
// });


Clarinet.test({
    name: 'Ensure that contract is initialized and token ID is zero',
    async fn(chain: Chain, accounts: Map<string, Account>, contracts: Map<string, Contract>) {
        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;
        console.log("deployer", deployer);
        console.log("wallet2_1", wallet_1);
        let block = chain.mineBlock([
            Tx.contractCall('sf-editions', 'get-last-token-id', [], wallet_1.address),
        ]);
        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectUint(0);
    },
});


Clarinet.test({
    name: "Mint an edition nft and verify it's properties",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        let deployer = accounts.get('deployer')!;
        let wallet_1 = accounts.get('wallet_1')!;
        let block = chain.mineBlock([
            Tx.contractCall('sf-editions', 'claim', [], wallet_1.address),
        ]);
        assertEquals(block.height, 2);
    },
});