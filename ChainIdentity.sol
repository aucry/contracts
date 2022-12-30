// SPDX-License-Identifier: MIT
// Created by Aucry.com - Cryptocurrency Auctions
pragma solidity ^0.8.7;
import "./includes/Structs.sol";

contract chainidentity {

    mapping(address => UserProfile) userProfiles;
    mapping(string => bool) usernameUniqueness;

    // User profile functions
    function checkUsernameExists(string memory desiredUsername) public view returns (bool answer) {
        //desiredUsername = StripTags.stripTags(desiredUsername, false, 20, 1, "");
        if(usernameUniqueness[desiredUsername]) {
            answer = true;
        } else {
            answer = false;
        }
    }

    function checkUsernameExistsWithPreSanitization(string memory desiredUsername) internal view returns (bool answer) {
        if(usernameUniqueness[desiredUsername]) {
            answer = true;
        } else {
            answer = false;
        }
    }

    function setUserProfileData(string memory desiredUsername, string memory avatarPart1, string memory avatarPart2) public returns (UserProfile memory userProfile) {
        //desiredUsername = StripTags.stripTags(desiredUsername, false, 20, 1, "");

        // allow existing users to update their profile picture
        if(keccak256(bytes(userProfiles[address(msg.sender)].userName)) != keccak256(bytes(" "))
            && keccak256(bytes(userProfiles[address(msg.sender)].userName)) != keccak256(bytes(desiredUsername))) {
            require(!checkUsernameExistsWithPreSanitization(desiredUsername), "USERNAME_EXISTS");
        }

        //profilePicture = StripTags.stripTags(profilePicture, false, 1024, 30, "https://images.unsplash.com/");
        userProfiles[address(msg.sender)].userName = desiredUsername;
        userProfiles[address(msg.sender)].avatarPart1 = avatarPart1;
        userProfiles[address(msg.sender)].avatarPart2 = avatarPart2;
        userProfiles[address(msg.sender)].userAddress = msg.sender;
        userProfile = userProfiles[address(msg.sender)];

    }

    function getUserProfileData(address userAddress) public view returns (UserProfile memory userProfile) {
        if(keccak256(bytes(userProfiles[address(userAddress)].userName)) != keccak256(bytes(""))) {
            userProfile = userProfiles[address(userAddress)];
        } else {
            userProfile = UserProfile("Anonymous","","",0,0,0, userAddress);
        }
    }

}