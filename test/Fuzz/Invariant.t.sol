// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {Test, console} from "lib/forge-std/src/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {HelperConfig} from "../../script/HelperConfihg.s.sol";
import {Handler} from "./Handler.t.sol";
import {DeployDsc} from "../../script/DeployDsc.s.sol";
import {ERC20Mock} from "@OpenZeppelin/mocks/ERC20Mock.sol";
import {IERC20} from "@OpenZeppelin/token/ERC20/IERC20.sol";

contract Invariant is StdInvariant, Test {
    DecentralizedStableCoin public dsc;
    DSCEngine public dsce;
    HelperConfig public config;
    Handler public handler;
    DeployDsc public deployer;

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

    function setUp() external {
        deployer = new DeployDsc();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerkey) = config.activeNetworkConfig();
        handler = new Handler(dsc, dsce);
        targetContract(address(handler));
        //targetContract(address(ethUsdPriceFeed));
    }

    function invariant_ProtocaolMustHaveMoreValueThenToatalSupply() public view {
        uint256 totalSupply = dsc.totalSupply();

        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));
        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        console.log("Weth Value:", wethValue);
        console.log("Wbtc Value:", wbtcValue);
        console.log("totalSupply:", totalSupply);
        console.log("timesMintIsCalled:", handler.timesMintIsCalled());

        assert(wethValue + wbtcValue >= totalSupply);
    }
}
