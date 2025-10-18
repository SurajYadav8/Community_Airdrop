//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {DeGuild} from "../src/DeGuild.sol";

contract MerkleAirdropTest is Test {
    MerkleAirdrop public airdrop;
    DeGuild public token;

    bytes32 public Root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4; // Merkle Root to verify the eligibility of airdrop claims
    uint256 public Amount_To_Claim = 25 * 1e18;
    uint256 public Amount_To_Send = Amount_To_Claim * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

    bytes32[] Proof = [proofOne, proofTwo];
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        token = new DeGuild();
        airdrop = new MerkleAirdrop(Root, token);
        token.mint(token.owner(), Amount_To_Send);
        token.transfer(address(airdrop), Amount_To_Send);
        (user, userPrivateKey) = makeAddrAndKey("user"); // foundry cheatcode to make fake user and private key for testing
    }

    function testUserClaim() public {
        uint256 initialBalance = token.balanceOf(user);

        vm.prank(user);
        airdrop.claimAirdrop(user, Amount_To_Claim, Proof);
        uint256 finalBalance = token.balanceOf(user);
        assertEq(finalBalance - initialBalance, Amount_To_Claim);
    }

    // console.log("Claimed");

}
