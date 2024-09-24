// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy, ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFToken, IStaking} from "./interfaces/Fluid.sol";
import {UniswapV3Swapper} from "@periphery/swappers/UniswapV3Swapper.sol";

contract FluidStakingLender is BaseStrategy, UniswapV3Swapper {
    using SafeERC20 for ERC20;

    address public immutable fToken;

    bool public stake = true;
    address public immutable staking;
    
    bool public claimRewards;
    address public immutable rewardsToken;
    address public immutable weth;
    uint256 internal constant ASSET_DUST = 100;

    constructor(address _asset, address _fToken, address _staking, address _weth, uint24 _rewardToBase, uint24 _baseToAsset, string memory _name) BaseStrategy(_asset, _name) {
        require(IFToken(_fToken).asset() == _asset, "!asset");
        require(IStaking(_staking).stakingToken() == _fToken, "!staking");
        rewardsToken = IStaking(_staking).rewardsToken();
        require(rewardsToken != address(0), "!rewardsToken");

        fToken = _fToken;
        staking = _staking;
        weth = _weth;
        base = _weth;

        _setUniFees(rewardsToken, _weth, _rewardToBase);
        _setUniFees(_weth, address(asset), _baseToAsset);
        
        asset.forceApprove(_fToken, type(uint256).max);
        ERC20(_fToken).forceApprove(_staking, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        uint256 shares = IFToken(fToken).deposit(_amount, address(this));
        if (stake) {
            IStaking(staking).stake(shares);
        }
    }

    function _freeFunds(uint256 _amount) internal override {
        uint256 shares = IFToken(fToken).convertToShares(_amount);
        uint256 balance = balanceOfFToken();
        if (shares > balance) {
            IStaking(staking).withdraw(shares - balance);
            shares = _min(shares, balanceOfFToken());
        }
        IFToken(fToken).redeem(shares, address(this), address(this));
    }

    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
        if (claimRewards) {
            IStaking(staking).getReward();
            _swapFrom(rewardsToken, address(asset), balanceOfRewards(), 0); // minAmountOut = 0 since we only sell rewards
        }

        uint256 balance = balanceOfAsset();
        if (TokenizedStrategy.isShutdown()) {
            _totalAssets = balance + totalInvestment();
        } else {
            if (balance > ASSET_DUST) {
                _deployFunds(balance);
            }
            _totalAssets = totalInvestment();
        }
    }

    function availableDepositLimit(address) public view virtual override returns (uint256) {
        return IFToken(fToken).maxDeposit(address(this));
    }

    function availableWithdrawLimit(address) public view virtual override returns (uint256) {
        return balanceOfAsset() + fTokenMaxWithdraw();
    }

    function fTokenMaxWithdraw() public view returns (uint256) {
        return IFToken(fToken).convertToAssets(_min(balanceOfFToken() + balanceOfStake(), IFToken(fToken).maxRedeem(address(staking))));
    }

    function balanceOfAsset() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function balanceOfFToken() public view returns (uint256) {
        return ERC20(fToken).balanceOf(address(this));
    }

    function balanceOfStake() public view returns (uint256 _amount) {
        return ERC20(staking).balanceOf(address(this));
    }

    function balanceOfRewards() public view returns (uint256) {
        return ERC20(rewardsToken).balanceOf(address(this));
    }

    function totalInvestment() public view returns (uint256) {
        return IFToken(fToken).convertToAssets(balanceOfFToken() + balanceOfStake());
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //////// EXTERNAL
    /**
     * @notice Set wether to stake or not stake fToken into the staking contract
     * @param _stake bool to stake the fToken or not
     */
    function setStake(bool _stake) external onlyManagement {
        stake = _stake;
    }

    /**
     * @notice Set the `claimRewards` bool.
     * @dev For management to set if the strategy should claim rewards during reports.
     * Can be turned off due to rewards being turned off or cause of an issue
     * in either the strategy or compound contracts.
     *
     * @param _claimRewards Bool representing if rewards should be claimed.
     */
    function setClaimRewards(bool _claimRewards) external onlyManagement {
        claimRewards = _claimRewards;
    }

    /**
     * @notice Set the minimum amount of rewardsToken to sell
     * @param _minAmountToSell minimum amount to sell in wei
     */
    function setMinAmountToSell(uint256 _minAmountToSell) external onlyManagement {
        minAmountToSell = _minAmountToSell;
    }

    /**
     * @notice Swap the base token between `asset` and `weth`.
     * @dev This can be used for management to change which pool
     * to trade reward tokens.
     */
    function swapBase() external onlyManagement {
        base = base == address(asset) ? weth : address(asset);
    }

    function _emergencyWithdraw(uint256 _amount) internal virtual override {
        _freeFunds(_min(_amount, fTokenMaxWithdraw()));
    }
}
