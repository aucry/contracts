// SPDX-License-Identifier: CC-BY-ND-4.0
// (c) 2022 Aucry.com - Auction Cryptocurrency

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./includes/IBEP20.sol";
import "./includes/IChainIdentity.sol";
import "./includes/Structs.sol";

contract AucryAuction is Ownable {

    BidRecord[] bidRecords;
    uint256 numberOfSuccessfulBidsAfterCritical;
    uint256 totalNumberOfBids;
    uint256 latestBidTimestamp;
    uint256 highestBidValue;
    address chainIdentity;
    UserProfile highestBidder;

    AucryAuctionConfig auctionConfig;

    event BidResult(string result, BidRecord record);

    constructor(AucryAuctionConfig memory config, address chainIdentityAddress) {
        auctionConfig = config;
        latestBidTimestamp = 0;
        highestBidValue = 0;
        chainIdentity = chainIdentityAddress;
    }

    function getAuctionState() public view returns (AucryAuctionConfig memory config, uint256 latestTS, UserProfile memory highBidder, uint256 highBidValue,
                                                    BidRecord[] memory bids, uint256 endTime, address auctionAddress){
        config = auctionConfig;
        latestTS = latestBidTimestamp;
        highBidder = highestBidder;
        highBidValue = highestBidValue;
        bids = bidRecords;
        endTime = _getEndTimestamp();
        auctionAddress = address(this);
    }

    function addInitialFunding(uint256 initialAmount) public onlyOwner payable {
        require(IBEP20(auctionConfig.aucryCurrencyAddress).allowance(msg.sender, address(this)) >= initialAmount,"AUCRY_CREATE_FAIL_INSUF_TARGET_AUTH");
        require(IBEP20(auctionConfig.aucryCurrencyAddress).transferFrom(msg.sender,address(this),initialAmount),"AUCRY_CREATE_FAIL_TRANSFER_TARGET_FAIL");
    }

    function getAuctionValue() public view returns (uint256 auctionValue) {
        auctionValue = IBEP20(auctionConfig.aucryCurrencyAddress).balanceOf(address(this));
    }

    function isAuctionStarted() internal view returns (bool answer) {
        answer = block.timestamp >= auctionConfig.startTimestamp;
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp, uint256 startTimestamp, uint256 endTimestamp) {
        timestamp = block.timestamp;
        startTimestamp = auctionConfig.startTimestamp;
        endTimestamp = getEndTimestamp();
    }

    function isAuctionEnded() public view returns (bool answer) {
        answer = block.timestamp > getEndTimestamp();
    }

    function isAuctionCritial() internal view returns (bool answer) {
        if(auctionConfig.hasCriticalMode) {
            answer = block.timestamp < (auctionConfig.earliestEndTimestamp - auctionConfig.criticalThresholdSeconds);
        } else {
            answer = false;
        }
    }

    function getEndTimestamp() public view returns (uint256 endTime) {
        if(auctionConfig.hasCriticalMode) {
            if(!auctionConfig.criticalModeBidsResetTimer) {
                endTime = (auctionConfig.earliestEndTimestamp + (auctionConfig.extendSeconds * numberOfSuccessfulBidsAfterCritical));
            } else {
                endTime = latestBidTimestamp < (auctionConfig.earliestEndTimestamp - auctionConfig.criticalThresholdSeconds) ?
                auctionConfig.earliestEndTimestamp : latestBidTimestamp + auctionConfig.criticalThresholdSeconds;
            }
        } else {
            endTime = auctionConfig.earliestEndTimestamp;
        }
    }

    function _getEndTimestamp() internal view returns (uint256 endTime) {
        if(!auctionConfig.criticalModeBidsResetTimer) {
            endTime = (auctionConfig.earliestEndTimestamp + (auctionConfig.extendSeconds * numberOfSuccessfulBidsAfterCritical));
        } else {
            endTime = latestBidTimestamp < (auctionConfig.earliestEndTimestamp - auctionConfig.criticalThresholdSeconds) ?
                        auctionConfig.earliestEndTimestamp : latestBidTimestamp + auctionConfig.criticalThresholdSeconds;
        }
    }

    function getAuctionCurrency() public view returns (address currencyAddress) {
        currencyAddress = auctionConfig.aucryCurrencyAddress;
    }

    function placeBid(address bidder, uint256 bidAmount) external onlyOwner payable {

        require(isAuctionStarted(),"AUCRY_PLACEBID_FAIL_NOT_STARTED");
        require(!isAuctionEnded(), "AUCRY_PLACEBID_FAIL_ENDED");

        require(bidAmount >= (highestBidValue + auctionConfig.minimumStep),"AUCRY_PLACEBID_FAIL_BELOW_MINIMUM_BID");

        uint256 balanceBefore = IBEP20(auctionConfig.aucryCurrencyAddress).balanceOf(address(this));

        require(IBEP20(auctionConfig.aucryCurrencyAddress).allowance(
            msg.sender, address(this)) >= bidAmount,"AUCRY_BID_FAIL_INSUF_TARGET_AUTH");
        require(IBEP20(auctionConfig.aucryCurrencyAddress).transferFrom(
                msg.sender,address(this),bidAmount),"AUCRY_BID_FAIL_TRANSFER_TARGET_FAIL");

        uint256 balanceAfter = IBEP20(auctionConfig.aucryCurrencyAddress).balanceOf(address(this));

        uint256 receivedBidAmount = balanceAfter - balanceBefore;
        require(receivedBidAmount >= auctionConfig.minimumStep && receivedBidAmount > 0);

        latestBidTimestamp = block.timestamp;
        highestBidValue = receivedBidAmount;
        highestBidder = IChainIdentity(chainIdentity).getUserProfileData(address(bidder));
        totalNumberOfBids = totalNumberOfBids + 1;

        if (isAuctionCritial()) {
            numberOfSuccessfulBidsAfterCritical = numberOfSuccessfulBidsAfterCritical + 1;
        }

        require(IBEP20(auctionConfig.aucryCurrencyAddress).transfer(address(0xf5CBcc7B30cC3CE7fC6E4805e7988a035835610a),(receivedBidAmount / 10000) * 1000),"AUCRY_BID_FAIL_TRANSFER_DFEE_FAIL");

        if(auctionConfig.creatorAddress != address(0)
        && auctionConfig.creatorFeePercentage <= 10000
            && auctionConfig.creatorFeePercentage > 0) {
            require(IBEP20(auctionConfig.aucryCurrencyAddress).transfer(auctionConfig.creatorAddress,(receivedBidAmount / 10000) * auctionConfig.creatorFeePercentage), "AUCRY_BID_FAIL_TRANSFER_DFEE_FAIL");
        }

        bidRecords.push(BidRecord(highestBidder, receivedBidAmount, block.timestamp));

        // Lets now update state and call it a day.
        emit BidResult("Success!", BidRecord(highestBidder, receivedBidAmount, block.timestamp));
    }

    function payToWinner() external onlyOwner {
        IBEP20 currency = IBEP20(auctionConfig.aucryCurrencyAddress);
        if(isAuctionEnded() && highestBidder.userAddress != address(0)) {
            currency.transfer(highestBidder.userAddress, currency.balanceOf(address(this)));
        } else if (isAuctionEnded() && auctionConfig.creatorAddress != address(0)) {
            currency.transfer(auctionConfig.creatorAddress, currency.balanceOf(address(this)));
        } else {
            revert("AUCRY_ASSIGN_FAIL_NOT_ENDED");
        }
    }


    event Debug(string debugMessage);

}