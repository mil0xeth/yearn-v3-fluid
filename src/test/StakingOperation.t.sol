// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest} from "./Operation.t.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Setup} from "./utils/Setup.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";
import {FluidStakingLenderFactory, FluidStakingLender} from "../FluidStakingLenderFactory.sol";

contract StakingOperationTest is OperationTest {
    function setUp() public override {
        //super.setUp();
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        //Mainnet:
        asset = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USDC
        fToken = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33; //fUSDC
        staking = 0x2fA6c95B69c10f9F52b8990b6C03171F13C46225;
        rewardToBase = 10000; //INST --> WETH
        baseToAsset = 500; //WETH --> USDC
        
        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

        //Arbitrum:
        //rewardToBase = 500;
        //baseToAsset = 500;

        stakingLenderFactory = new FluidStakingLenderFactory(management, performanceFeeRecipient, keeper, management, weth);
        strategy = IStrategyInterface(address(stakingLenderFactory.newFluidStakingLender(address(asset), fToken, staking, rewardToBase, baseToAsset, "Tokenized Strategy")));
        vm.prank(management);
        strategy.acceptManagement();


        // Set decimals
        decimals = asset.decimals();
        factory = strategy.FACTORY();
        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        vm.label(factory, "factory");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(address(strategy), "strategy");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
    }
}