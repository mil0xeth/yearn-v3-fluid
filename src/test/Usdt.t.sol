// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest, ERC20} from "./Operation.t.sol";
import {ShutdownTest} from "./Shutdown.t.sol";

import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";
import {CompoundV3LenderFactory, CompoundV3Lender} from "../CompoundV3LenderFactory.sol";

contract UsdtOperationTest is OperationTest {
    function setUp() public virtual override {
        super.setUp();

        asset = ERC20(tokenAddrs["USDT"]);

        comet = 0x3Afdc9BCA9213A35503b077a6072F3D0d5AB0840;

        // Set decimals
        decimals = asset.decimals();

        strategy = IStrategyInterface(setUpStrategy());
    }

    // No USDT/COMP liquidity
    function test_switchBase(uint256 _amount) public override {
        return;
    }
}

contract UsdtShutdownTest is ShutdownTest {
    function setUp() public virtual override {
        super.setUp();

        asset = ERC20(tokenAddrs["USDT"]);

        comet = 0x3Afdc9BCA9213A35503b077a6072F3D0d5AB0840;

        // Set decimals
        decimals = asset.decimals();

        strategy = IStrategyInterface(setUpStrategy());
    }
}
