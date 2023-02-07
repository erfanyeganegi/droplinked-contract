# droplinked-contract

droplinked is the decentralized commerce infrastructure protocol. as a commerce infrastructure network operating as a decentralized inventory management and sales tracking system for digital and physical goods. 

version: 1.0.0
summary: droplinked smart contract for Stacks blockchain

## Traits
droplinked smart contract implements `sft-trait`. sft (semi-fungible token) are digital assets that sit between fungible and non-fungible tokens. [Read more about semi-fungible tokens](https://github.com/stacksgov/sips/blob/main/sips/sip-013/sip-013-semi-fungible-token-standard.md)

sft-trait is implemented and inherently uses **droplinked nft-fractionalizer** to create **SKU (Stock Keeping Unit)** and **product** tokens.

## Tokens
### SKU (non-fungible token)
**sku** is a non-fungible token defined in droplinked smart contract to represent unique set of **products**.

### Product (fungible token)
**product** is a fungible token defined in droplinked smart contract to represent single product of a **sku**.

note that using **sft-trait** and **droplinked nft-fractionalizer** we can define unlimited number of **skus** and **products** in smart contract.

## Constants
### Error Codes
