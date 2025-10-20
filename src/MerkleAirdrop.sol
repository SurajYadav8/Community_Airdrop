// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP721} from "@openzeppelin/contracts/utils/cryptography/draft-EIP721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;
    // some list of addresses
    // Allow someone to claim tokens if they are in the list

    error MerkleAirdrop_InvalidProof();
    error MerkleAirdrop_AlreadyClaimed();
    error MerkleAirdrop_InvalidSignature();

    address[] eligible;
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_TOKEN;
    mapping(address eligible => bool claimed) private hasclaimed;
    bytes32 private constant MESSAGETYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");


    struct AirdropClaim {
        address account;
        uint256 amount;
    }
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
    constructor(bytes32 merkleRoot, IERC20 token) EIP721("MerkleAirdrop", "1") {
        I_MERKLE_ROOT = merkleRoot;
        I_TOKEN = token;
    }

    function claimAirdrop(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if (hasclaimed[account]) {
            revert MerkleAirdrop_AlreadyClaimed();
        }

        if(!_isValidSignature( account, getMessage(account, amount), v, r, s) ){
            revert MerkleAirdrop_InvalidSignature();
        }
        // bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount)))); // works too but more expensive

        bytes32 leaf; // declared outside so do not clash between YUL and solidity

        // Using YUL assembly to optimize gas cost
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, account)
            mstore(add(ptr, 0x20), amount)
            let firstHash := keccak256(ptr, 0x40)

            mstore(ptr, firstHash)
            leaf := keccak256(ptr, 0x20)
        }

        hasclaimed[account] = true;

        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leaf)) {
            revert MerkleAirdrop_InvalidProof();
        }

        emit ClaimAirdrop(account, amount);
        I_TOKEN.safeTransfer(account, amount);
    }

    function getMessage(address account, uint256 amount) public view returns (bytes32){
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGETYPEHASH,AirdropClaim({account: account, amount: amount})))
        );
    }

    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLE_ROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_TOKEN;
    
    }
    
    
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool){
        (address actualSigner, , ) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }
}
