// SPDX-License-Identifier: CC-BY-ND-4.0
// (c) 2022 Aucry.com - Auction Cryptocurrency
pragma solidity ^0.8.7;

import "./AucryAuction.sol";
import "./includes/IBEP20.sol";
import "./includes/Structs.sol";

contract AucryHub {

    mapping(address => address[]) aucryAuctions;    // currency => contract
    mapping(address => address[]) aucryFinishedAuctions;    // currency => contract
    address chainIdentity;

    constructor(address chainIdentityAddress) {
        chainIdentity = chainIdentityAddress;
    }

    // Auction Operation Functions
    function newAucry(AucryAuctionConfig memory au, uint256 initialContractValue) external returns(address createdContractAddress) {

        require(IBEP20(au.aucryCurrencyAddress).allowance(msg.sender, address(this)) >= initialContractValue,"AUCRY_CREATE_FAIL_INSUF_AUTH");
        require(IBEP20(au.aucryCurrencyAddress).transferFrom(msg.sender,address(this),initialContractValue),"AUCRY_CREATE_FAIL_TRANSFER_FAIL");

        uint256 initialAmountReceived = IBEP20(au.aucryCurrencyAddress).balanceOf(address(this));
        AucryAuction created = new AucryAuction(au, chainIdentity);

        require(IBEP20(au.aucryCurrencyAddress).approve(address(created), initialAmountReceived),"AUCRY_CREATE_FAIL_APPROVE_SUBTFR");

        created.addInitialFunding(initialAmountReceived);

        migrateFinishedAucrys(address(au.aucryCurrencyAddress));
        aucryAuctions[address(au.aucryCurrencyAddress)].push(address(created));

        createdContractAddress = address(created);
    }

    function migrateFinishedAucrys(address targetAddress) public payable {
        for(uint256 i = 0; i < aucryAuctions[targetAddress].length; i++) {
            if(AucryAuction(aucryAuctions[targetAddress][i]).isAuctionEnded()) {
                aucryFinishedAuctions[targetAddress].push(aucryAuctions[targetAddress][i]);
                if(i < aucryAuctions[targetAddress].length - 1) {
                    aucryAuctions[targetAddress][i] = aucryAuctions[targetAddress][aucryAuctions[targetAddress].length - 1];
                }
                aucryAuctions[targetAddress].pop();
            }
        }
    }

    function activeAucrysForCurrency(address aucryCurrencyAddress) public view returns (address[] memory addressBook) {
        addressBook = aucryAuctions[aucryCurrencyAddress];
    }


    function endedAucrysForCurrency(address aucryCurrencyAddress) public view returns (address[] memory addressBook) {
        addressBook = aucryFinishedAuctions[aucryCurrencyAddress];
    }

    function placeBid(address aucryAddress, uint256 bidAmount) external payable {
        address auctionCurrency = AucryAuction(aucryAddress).getAuctionCurrency();

        require(IBEP20(auctionCurrency).allowance(msg.sender, address(this)) >= bidAmount,"AUCRY_BID_FAIL_INSUF_AUTH");
        require(IBEP20(auctionCurrency).transferFrom(msg.sender,address(this),bidAmount),"AUCRY_BID_FAIL_TRANSFER_FAIL");
        uint256 bidAmountReceived = IBEP20(auctionCurrency).balanceOf(address(this));

        require(IBEP20(auctionCurrency).approve(aucryAddress, bidAmountReceived),"AUCRY_BID_FAIL_APPROVE_SUBTFR");

        AucryAuction(aucryAddress).placeBid(msg.sender, bidAmountReceived);

    }

    function claimWonAucry(address aucryAddress) public {
        AucryAuction(aucryAddress).payToWinner();
    }

    event Debug(string debugMessage);
}