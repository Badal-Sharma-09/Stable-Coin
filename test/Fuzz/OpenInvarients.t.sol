// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HelperConfig} from "../../script/HelperConfihg.s.sol";
import {ContinueOnRevertHandler} from "./ContinueOnRevertHandler.t.sol";
import {DeployDsc} from "../../script/DeployDsc.s.sol";
import {ERC20Mock} from "@OpenZeppelin/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;
    HelperConfig public config;
    ContinueOnRevertHandler public handler;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 deployerkey;

    uint256 public amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;

    uint256 public STARTING_USER_BALANCE = 10 ether;
    address public USER = makeAddr("user");
    uint256 public constant MIN_HEALTH_FACTOR = 1e18;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;

    // Liquidation
    address public liquidator = makeAddr("liquidator");
    uint256 public collateralToCover = 20 ether;

     function setUp() public {
        DeployDsc deployer = new DeployDsc();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerkey) = config.activeNetworkConfig();
         handler = new ContinueOnRevertHandler(dsce, dsc);
         targetContract(address(handler));
         // targetContract(address(ethUsdPriceFeed)); Why can't we just do this?
     }
}