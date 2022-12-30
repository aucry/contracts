# Aucry Solidity Contracts

In an effort to increase trust and transparency, we are publishing our smart contract source code on both GitHub (while in development) and BSCScan (once ready to launch). 

*This repo is a work in progress and currently AucryHub is oversize.
We welcome pull requests and issues from the community.*

### Repo Root:

#### AucryHub.sol
This is our factory contract, responsible for creation and oversight of the Aucry auctions taking place on the platform.
When a new auction is created, the AucryHub contract deploys a new AucryAuction to mainnet with the desired configuration.

#### AucryAuction.sol 
This contract is deployed each time a new auction is created. It checks that bids are valid and acts as holding pen for the initial auction value and bid tokens.

#### ChainIdentity.sol
ChainIdentity is our very own profile system. It enables a user to pick a unique username and an avatar by way of choosing an unsplash image. This image contains a two part ID, which we use in the UI to render the user avatar.

### Includes folder

#### includes/IBEP20.sol
The BEP20 interface.

#### includes/Structs.sol
Defines several structs in a common library used throughout the project.

#### includes/IChainIdentity.sol
The ChainIdentity interface.

