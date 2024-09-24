// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import "forge-std/console.sol";
import {ExtendedTest} from "./ExtendedTest.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {FluidLenderFactory, FluidLender} from "../../FluidLenderFactory.sol";
import {FluidStakingLenderFactory, FluidStakingLender} from "../../FluidStakingLenderFactory.sol";
import {IStrategyInterface} from "../../interfaces/IStrategyInterface.sol";

// Inherit the events so they can be checked if desired.
import {IEvents} from "@tokenized-strategy/interfaces/IEvents.sol";

interface IFactory {
    function governance() external view returns (address);

    function set_protocol_fee_bps(uint16) external;

    function set_protocol_fee_recipient(address) external;
}

contract Setup is ExtendedTest, IEvents {
    using SafeERC20 for ERC20;

    // Contract instancees that we will use repeatedly.
    ERC20 public asset;
    IStrategyInterface public strategy;

    address fToken;
    address staking;
    address weth;
    uint24 rewardToBase; 
    uint24 baseToAsset;

    FluidLenderFactory public lenderFactory;
    FluidStakingLenderFactory public stakingLenderFactory;

    // Addresses for different roles we will use repeatedly.
    address public user = address(10);
    address public keeper = address(4);
    address public management = address(1);
    address public performanceFeeRecipient = address(3);

    // Address of the real deployed Factory
    address public factory;

    // Integer variables that will be used repeatedly.
    uint256 public decimals;
    uint256 public MAX_BPS = 10_000;

    uint256 public maxFuzzAmount = 10e6 * 1e6;
    uint256 public minFuzzAmount = 1e5;

    uint256 public profitMaxUnlockTime = 0;

    function setUp() public virtual {
        uint256 mainnetFork = vm.createFork("mainnet");
        vm.selectFork(mainnetFork);

        //// FLUID LENDER
        //Mainnet:
        /*
        asset = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); //USDC
        fToken = 0x9Fb7b4477576Fe5B32be4C1843aFB1e55F251B33; //fUSDC
        maxFuzzAmount = 10e6 * 1e6;
        minFuzzAmount = 1e5;
        
        asset = ERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); //USDT
        fToken = 0x5C20B550819128074FD538Edf79791733ccEdd18; //fUSDT
        maxFuzzAmount = 1e6 * 1e6;
        minFuzzAmount = 1e5;
        */
        asset = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //WETH
        fToken = 0x90551c1795392094FE6D29B758EcCD233cFAa260; //fWETH
        maxFuzzAmount = 500 * 1e18;
        minFuzzAmount = 1e14;
        /*
        asset = ERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0); //wstETH
        fToken = 0x2411802D8BEA09be0aF8fD8D08314a63e706b29C; //fwstETH
        maxFuzzAmount = 500 * 1e18;
        minFuzzAmount = 1e14;
        */

        weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        

        lenderFactory = new FluidLenderFactory(management, performanceFeeRecipient, keeper, management);

        // Set decimals
        decimals = asset.decimals();

        // Deploy strategy and set variables
        strategy = IStrategyInterface(setUpStrategy());

        factory = strategy.FACTORY();

        // label all the used addresses for traces
        vm.label(keeper, "keeper");
        vm.label(factory, "factory");
        vm.label(address(asset), "asset");
        vm.label(management, "management");
        vm.label(address(strategy), "strategy");
        vm.label(performanceFeeRecipient, "performanceFeeRecipient");
    }

    function setUpStrategy() public returns (address) {
        //// FLUID LENDER
        IStrategyInterface _strategy = IStrategyInterface(address(lenderFactory.newFluidLender(address(asset), fToken, "Tokenized Strategy")));
        //// FLUID STAKING LENDER
        //IStrategyInterface _strategy = IStrategyInterface(address(lenderFactory.newFluidLender(address(asset), fToken, staking, rewardToBase, baseToAsset, "Tokenized Strategy")));

        vm.prank(management);
        _strategy.acceptManagement();

        return address(_strategy);
    }

    function depositIntoStrategy(
        IStrategyInterface _strategy,
        address _user,
        uint256 _amount
    ) public {
        vm.startPrank(_user);
        asset.safeApprove(address(_strategy), _amount);

        _strategy.deposit(_amount, _user);
        vm.stopPrank();
    }

    function mintAndDepositIntoStrategy(
        IStrategyInterface _strategy,
        address _user,
        uint256 _amount
    ) public {
        airdrop(asset, _user, _amount);
        depositIntoStrategy(_strategy, _user, _amount);
    }

    // For checking the amounts in the strategy
    function checkStrategyTotals(
        IStrategyInterface _strategy,
        uint256 _totalAssets,
        uint256 _totalDebt,
        uint256 _totalIdle
    ) public {
        uint256 _assets = _strategy.totalAssets();
        uint256 _balance = ERC20(_strategy.asset()).balanceOf(
            address(_strategy)
        );
        uint256 _idle = _balance > _assets ? _assets : _balance;
        uint256 _debt = _assets - _idle;
        assertEq(_assets, _totalAssets, "!totalAssets");
        assertEq(_debt, _totalDebt, "!totalDebt");
        assertEq(_idle, _totalIdle, "!totalIdle");
        assertEq(_totalAssets, _totalDebt + _totalIdle, "!Added");
    }

    function airdrop(ERC20 _asset, address _to, uint256 _amount) public {
        uint256 balanceBefore = _asset.balanceOf(_to);
        deal(address(_asset), _to, balanceBefore + _amount);
    }

    function getExpectedProtocolFee(
        uint256 _amount,
        uint16 _fee
    ) public view returns (uint256) {
        uint256 timePassed = block.timestamp - strategy.lastReport();

        return (_amount * _fee * timePassed) / MAX_BPS / 31_556_952;
    }

    function setFees(uint16 _protocolFee, uint16 _performanceFee) public {
        address gov = IFactory(factory).governance();

        // Need to make sure there is a protocol fee recipient to set the fee.
        vm.prank(gov);
        IFactory(factory).set_protocol_fee_recipient(gov);

        vm.prank(gov);
        IFactory(factory).set_protocol_fee_bps(_protocolFee);

        vm.prank(management);
        strategy.setPerformanceFee(_performanceFee);
    }
}
