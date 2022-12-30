// SPDX-License-Identifier: MIT
// Created by Aucry.com - Cryptocurrency Auctions
pragma solidity ^0.8.7;

import "./Structs.sol";

interface IChainIdentity {

    function checkUsernameExists(string memory desiredUsername) external view returns (bool answer);
    function setUserProfileData(string memory desiredUsername, string memory profilePicture) external returns (UserProfile memory userProfile);
    function getUserProfileData(address userAddress) external view returns (UserProfile memory userProfile);

}