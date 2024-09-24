// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest} from "./Operation.t.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Setup} from "./utils/Setup.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";
import {FluidStakingLenderFactory, FluidStakingLender} from "../FluidStakingLenderFactory.sol";

contract StakingOperationUSDCArbitrumTest is OperationTest {
    function setUp() public override {
        //super.setUp();
        uint256 arbitrumFork = vm.createFork("arbitrum");
        vm.selectFork(arbitrumFork);

        //Mainnet:
        asset = ERC20(0xaf88d065e77c8cC2239327C5EDb3A432268e5831); //USDC
        fToken = 0x1A996cb54bb95462040408C06122D45D6Cdb6096; //fUSDC
        staking = 0x48f89d731C5e3b5BeE8235162FC2C639Ba62DB7d;
        rewardToBase = 500; //INST --> WETH
        baseToAsset = 500; //WETH --> USDC
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