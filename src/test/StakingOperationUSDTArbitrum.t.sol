// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest} from "./Operation.t.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Setup} from "./utils/Setup.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";
import {FluidStakingLenderFactory, FluidStakingLender} from "../FluidStakingLenderFactory.sol";

contract StakingOperationUSDTArbitrumTest is OperationTest {
    function setUp() public override {
        //super.setUp();
        uint256 arbitrumFork = vm.createFork("arbitrum");
        vm.selectFork(arbitrumFork);

        //Arbitrum:
        asset = ERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9); //USDT
        fToken = 0x4A03F37e7d3fC243e3f99341d36f4b829BEe5E03; //fUSDT
        staking = 0x65241f6cacde58c03400Cb84542a2c197d6dE9C3;
        rewardToBase = 500; //INST --> WETH
        baseToAsset = 500; //WETH --> USDT
        maxFuzzAmount = 1e6 * 1e6;
        minFuzzAmount = 1e5;
        
        weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

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