// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//Toggle

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {ERC20Mock} from "@OpenZeppelin/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    ERC20Mock weth;
    ERC20Mock wbtc;
    MockV3Aggregator ethUsdPriceFeed;
    uint256 public constant MAX_DEPOSIT_SIZE = type(uint96).max;

    address[] usersWithDepositCollectoral;
    uint256 public timesMintIsCalled;

    constructor(DecentralizedStableCoin _dsc, DSCEngine _dsce) {
        dsce = _dsce;
        dsc = _dsc;

        address[] memory collectoralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collectoralTokens[0]);
        wbtc = ERC20Mock(collectoralTokens[1]);
        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    // FUNCTOINS TO INTERACT WITH

    ///////////////
    // DSCEngine //
    ///////////////

    function depositCollectoral(uint256 collectoralSeed, uint256 amountCollectoral) public {
        ERC20Mock collectoral = _getCollectoralFromSeed(collectoralSeed);
        amountCollectoral = bound(amountCollectoral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender);
        collectoral.mint(address(msg.sender), amountCollectoral);
        collectoral.approve(address(dsce), amountCollectoral);
        dsce.depositCollateral(address(collectoral), amountCollectoral);
        vm.stopPrank();
        usersWithDepositCollectoral.push(msg.sender);
    }

    function redeemCollectoral(uint256 collectoralSeed, uint256 amountCollectoral) public {
        ERC20Mock collectoral = _getCollectoralFromSeed(collectoralSeed);
        uint256 maxCollectoralToRedeem = dsce.getCollateralBalanceOfUser(address(collectoral), msg.sender);
        console.log("Max Collectoral To Redeem:", maxCollectoralToRedeem);
        amountCollectoral = bound(amountCollectoral, 0, maxCollectoralToRedeem);
        if (amountCollectoral == 0) {
            return;
        }
        dsce.redeemCollateral(address(collectoral), amountCollectoral);
    }

    function burnDsc(uint256 amountDsc, uint256 addressSeed) public {
        if (usersWithDepositCollectoral.length == 0) {
            return;
        }
        address sender = usersWithDepositCollectoral[addressSeed % usersWithDepositCollectoral.length];
        amountDsc = amountDsc = bound(amountDsc, 0, dsc.balanceOf(msg.sender));
        if (amountDsc == 0) {
            return;
        }
        vm.startPrank(sender);
        dsce.burnDsc(amountDsc);
        vm.stopPrank();
    }

    function mintDsc(uint256 amountDscToMint, uint256 addressSeed) public {
        if (usersWithDepositCollectoral.length == 0) {
            return;
        }
        address sender = usersWithDepositCollectoral[addressSeed % usersWithDepositCollectoral.length];
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);

        int256 maxDscToMint = int256(collateralValueInUsd / 2) - int256(totalDscMinted);
        if (maxDscToMint < 0) {
            return;
        }
        amountDscToMint = bound(amountDscToMint, 0, uint256(maxDscToMint));
        if (amountDscToMint == 0) {
            return;
        }
        vm.startPrank(sender);
        dsce.mintDsc(amountDscToMint);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function liquidate(uint256 collectoralSeed, address userToBeLiquidated, uint256 debtToCover) public {
        uint256 minHealthFactor = dsce.getMinHealthFactor();
        uint256 userHealthFactor = dsce.getHealthFactor(userToBeLiquidated);
        if (userHealthFactor >= minHealthFactor) {
            return;
        }

        ERC20Mock collectoral = _getCollectoralFromSeed(collectoralSeed);
        debtToCover = bound(debtToCover, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(userToBeLiquidated);
        dsce.liquidate(address(collectoral), address(userToBeLiquidated), debtToCover);
        vm.stopPrank();
    }

    /////////////////////////////
    // DecentralizedStableCoin //
    /////////////////////////////
    
    function transferDsc(uint256 amountDsc, address to) public {
        if (to == address(0)) {
            to = address(1);
        }
        amountDsc = bound(amountDsc, 0, dsc.balanceOf(msg.sender));
        vm.prank(msg.sender);
        dsc.transfer(to, amountDsc);
    }

    /////////////////////////////
    // Aggregator //
    /////////////////////////////

  function updateCollateralPrice(uint96 newPrice, uint256 collateralSeed) public {
        int256 intNewPrice = int256(uint256(newPrice));
        ERC20Mock collateral = _getCollectoralFromSeed(collateralSeed);
        MockV3Aggregator priceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(collateral)));

        priceFeed.updateAnswer(intNewPrice);
    }  

    //////////////////////
    // Helper functions //
    //////////////////////

    function _getCollectoralFromSeed(uint256 CollectoralSeed) public view returns (ERC20Mock) {
        if (CollectoralSeed % 2 == 0) {
            return weth;
        } else {
            return wbtc;
        }
    }
}
