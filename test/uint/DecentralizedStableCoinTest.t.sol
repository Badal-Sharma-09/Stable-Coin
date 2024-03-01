// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {HelperConfig} from "../../script/HelperConfihg.s.sol";

contract DecentralizedStableCoinTest is StdCheats, Test {
    DecentralizedStableCoin public dsc;

    function setUp() public {
        dsc = new DecentralizedStableCoin();
    }

    function testMustMintMoreThanZero() public {
        vm.prank(dsc.owner());
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__AmountMustMoreThanZero.selector);
        dsc.mint(address(this), 0);
    }

    function testMustBurnMoreThanZero() public {
        vm.prank(dsc.owner());
        dsc.mint(address(this), 20 ether);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__AmountMustMoreThanZero.selector);
        dsc.burn(0);
    }

    function testCantBurnMoreThanYouHave() public {
        vm.prank(dsc.owner());
        dsc.mint(address(this), 20 ether);
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__BurnAmountExceedsBalance.selector);
        dsc.burn(21 ether);
    }

    function testCantMintToZeroAddress() public {
        vm.prank(dsc.owner());
        vm.expectRevert(DecentralizedStableCoin.DecentralizedStableCoin__NotZeroAddress.selector);
        dsc.mint(address(0), 20 ether);
    }

    function testOwnerCanMintAndBurnTokens() public {
        vm.prank(dsc.owner());
        uint256 AmountBeforeMint = dsc.balanceOf(dsc.owner());
        dsc.mint(address(this), 20 ether);
        uint256 AmountAfterMint = dsc.balanceOf(dsc.owner());
        dsc.burn(20 ether);
        uint256 AmountAfterBurn = dsc.balanceOf(dsc.owner());

        console.log("Balance before Mint", AmountBeforeMint);
        console.log("Balance After Mint", AmountAfterMint);
        console.log("Balance After burn", AmountAfterBurn);
    }
}
