// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Simplify_314} from "../src/ERC314.sol";

contract SimpTest is Test {
    Simplify_314 public cusSimp;
    Simplify_314 public mainsimp;
    address whaleWallet = 0xB8cf7537Cd729bB83a0Fe5ddfE8a9850aBC87f8b;
    address testWallet = 0xF5ED007002Dd362B06284B26e451c3D54210848d;
    address payable mainAddr = payable(0x111fc50541cf398857DF38fA23D586C18E0f96cE);
    uint256 public mainFork;
    // uint256 tradeAmount = 1 ether;

    function setUp() public {
        mainFork = vm.createFork(vm.envString("MAIN_RPC_URL"));
        vm.selectFork(mainFork);
        mainsimp = Simplify_314(mainAddr);
        cusSimp = new Simplify_314();
        deal(testWallet, type(uint256).max);
    }

    function testInitialBalance() public view {
        uint256 balance = mainsimp.balanceOf(testWallet);
        assertGt(balance, 0);
        console.log("Balance: ", balance);
    }

    function getMaxAmount() internal view returns (uint256) {
        return mainsimp._maxWallet();
    }

    function selfTransferTest() public {
        vm.startPrank(testWallet);
        // Buy
        console.log("Initial ether bal: ", testWallet.balance, "Simp bal: ", mainsimp.balanceOf(testWallet));
        payable(address(mainsimp)).call{value: 1 ether}("");
        console.log("Trade 1 ether bal: ", testWallet.balance, "Simp bal: ", mainsimp.balanceOf(testWallet));

        // Roll block
        vm.roll(block.number + 1);

        // Self transfer check
        uint256 curBal = mainsimp.balanceOf(testWallet);
        mainsimp.transfer(testWallet, curBal);
        console.log("Simp bal: ", mainsimp.balanceOf(testWallet));

        vm.stopPrank();
    }

    // Fuzz test here
    function fuzzTestTrade(uint256 tradeAmount) public {
        // Set test condition
        tradeAmount = bound(tradeAmount, 0.1 ether, 10000 ether);
        require(tradeAmount >= 0.1 ether && tradeAmount <= 10000 ether, "Trade amount out of range");
        
        vm.startPrank(testWallet);
        // Buy
        uint256 preBal = testWallet.balance;
        // console.log("Initial ether bal: ", preBal, "Simp bal: ", mainsimp.balanceOf(testWallet));
        payable(address(mainsimp)).call{value: tradeAmount}("");
        // console.log("Trade 1 ether bal: ", testWallet.balance, "Simp bal: ", mainsimp.balanceOf(testWallet));

        // Roll block
        vm.roll(block.number + 1);

        // Sell
        uint256 curSimpBal = mainsimp.balanceOf(testWallet);
        mainsimp.transfer(address(mainsimp), curSimpBal);
        uint256 postBal = testWallet.balance;
        // console.log("Trade 2 ether bal: ", testWallet.balance, "Simp bal: ", mainsimp.balanceOf(testWallet));

        assertTrue(postBal <= preBal);

        vm.stopPrank();
    }
}

// forge test --match-contract SimpTest --match-test testTrade