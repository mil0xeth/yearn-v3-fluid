// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {OperationTest} from "./Operation.t.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Setup} from "./utils/Setup.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IStrategyInterface} from "../interfaces/IStrategyInterface.sol";
import {FluidStakingLenderFactory, FluidStakingLender} from "../FluidStakingLenderFactory.sol";

contract StakingOperationUSDTMainnetTest is OperationTest {
    function setUp() public override {
        //super.setUp();
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        //Arbitrum:
        asset = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); //USDT
        fToken = 0x5C20B550819128074FD538Edf79791733ccEdd18; //fUSDT
        staking = 0x490681095ed277B45377d28cA15Ac41d64583048;
        rewardToBase = 10000; //INST --> WETH
        baseToAsset = 3000; //WETH --> USDT
        maxFuzzAmount = 9e6 * 1e6;
        minFuzzAmount = 1e5;
        
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