// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MerkleAirdrop {
    // some list of addresses
    // Allow someone to claim tokens if they are in the list
    address[] eligibleAddresses;

    // function claimAirdrop(address eligibleAccount) external {
    //     for (uint256 i = 0; i < eligibleAddresses.length; i++) {
    //         if (eligibleAddresses[i] == eligibleAccount) {}
    //     }
    // }

    /**Note: using array to claim airdrop can be very costly and even sometimes fail due to gas limits.
     * For example if we have 1000 addresses in the array, then we will have to loop through 1000 addresses.
     * that's why we use Merkle Tree to optimize this process.
     */
}
