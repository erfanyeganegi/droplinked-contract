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
Before diving deep into the smart contract functionality to see how it operates, we list different error codes as result of failed function. These error codes are self-explanatory but a breif explanation is also given.

* **err-producer-only (u100)**: This error indicates that only the producer (holder of **products**) can call this function. This error is thrown when someone (wallet address) else than the real holder of a product is trying to change state of that product.
* **err-publisher-only (u101)**: *producers* and *publishers* are both holders of products. But the difference between them is determined when a wallet address (**publsiher**) requests a product from another wallet address (**producer**).
* **err-publisher-producer-selfsame (u102)**: This error is thrown when a wallet address (as **publisher**) is requesting a product from same wallet address (same address also as **producer**).
* **err-unauthorized (u102)**: some functions despite being public are not meant to be called directly by users (**producers** or **publishers**). They are public because it is required by `sft-trait` but they are called by smart contract as a result of other function calls by **producers** and **publisher**.