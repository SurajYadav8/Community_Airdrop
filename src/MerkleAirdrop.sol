// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    // some list of addresses
    // Allow someone to claim tokens if they are in the list

    error MerkleAirdrop_InvalidProof();

    address[] eligibleAddresses;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_TOKEN;

    event ClaimAirdrop(address account, uint256 amount);

    // function claimAirdrop(address eligibleAccount) external {
    //     for (uint256 i = 0; i < eligibleAddresses.length; i++) {
    //         if (eligibleAddresses[i] == eligibleAccount) {}
    //     }
    // }

    /**
     * Note: using array to claim airdrop can be very costly and even sometimes fail due to gas limits.
     * For example if we have 1000 addresses in the array, then we will have to loop through 1000 addresses.
     * that's why we use Merkle Tree to optimize this process.
     */
    constructor(bytes32 merkleRoot, IERC20 token) {
        I_MERKLE_ROOT = merkleRoot;
        I_TOKEN = token;
    }

    function claimAirdrop(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); // works too but more expensive

        bytes32 leaf; // declared outside so do not clash between YUL and solidity

        // Using YUL assembly to optimize gas cost
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, amount)
            mstore(add(ptr, 0x20), account)
            let firstHash := keccak256(ptr, 0x40)

            mstore(ptr, firstHash)
            leaf := keccak256(ptr, 0x20)
        }
        

        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        emit ClaimAirdrop(account, amount);
        I_TOKEN.safeTransfer(account, amount);
    }
}
