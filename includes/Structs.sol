// SPDX-License-Identifier: CC-BY-ND-4.0
// (c) 2022 Aucry.com - Auction Cryptocurrency
pragma solidity ^0.8.7;

    struct AucryAuctionConfig {
        uint256 startTimestamp;             // Start time for the auction
        string auctionName;                 // The name of the auction
        uint256 earliestEndTimestamp;       // Earliest time the auction can end
        uint16 criticalThresholdSeconds;    // How long before end time does Critical Mode activate
        bool criticalModeBidsResetTimer;    // Whether critical mode bids should reset the timer to the start of critical mode.
        uint16 extendSeconds;               // How many seconds does each bid extend end time in Critical Mode?
                                            // (Ignored if criticalModeBidsResetTimer = true)
        bool battleRoyaleMode;              // Is this a battle royale mode? In this mode, an ever decreasing
                                            // number of people who have bidded recently are allowed to bid again

        bool hasCriticalMode;               // Whether or not to enable critical mode at all
        uint256 reserve;                    // The minimum bid value at which this auction can be won.
        uint256 startingBid;                // the price the auction should start at
        uint256 minimumStep;                // What is the minimum difference between the previous highest bid and the new bid?
        address aucryCurrencyAddress;       // What currency are we bidding on?
        address creatorAddress;             // Who should receive the creator fee
        uint16 creatorFeePercentage;        // What percentage does the creator account get (if any)
    }

    struct UserProfile {
        string userName;
        string avatarPart1;
        string avatarPart2;
        uint256 auctionsWon;
        uint256 bidsPlaced;
        uint256 auctionsCreated;
        address userAddress;
    }

    struct AuctionState {
        AucryAuctionConfig config;
        uint256 latestBidTimestamp;
        address highestBidderAddress;
        uint256 highestBidValue;
        BidRecord[] bids;
        uint256 endTime;
        address auctionAddress;
    }

    struct BidRecord {
        UserProfile userProfile;
        uint256 bidAmount;
        uint256 bidTimestamp;
    }
