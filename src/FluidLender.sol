// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {BaseStrategy, ERC20} from "@tokenized-strategy/BaseStrategy.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFToken} from "./interfaces/Fluid.sol";

contract FluidLender is BaseStrategy {
    using SafeERC20 for ERC20;

    address public immutable fToken;
    uint256 internal constant ASSET_DUST = 100;

    constructor(address _asset, address _fToken, string memory _name) BaseStrategy(_asset, _name) {
        require(IFToken(_fToken).asset() == _asset, "!asset");
        fToken = _fToken;
        asset.forceApprove(_fToken, type(uint256).max);
    }

    function _deployFunds(uint256 _amount) internal override {
        IFToken(fToken).deposit(_amount, address(this));
    }

    function _freeFunds(uint256 _amount) internal override {
        IFToken(fToken).withdraw(_amount, address(this), address(this));
    }

    function _harvestAndReport() internal override returns (uint256 _totalAssets) {
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
        return balanceOfAsset() + IFToken(fToken).maxWithdraw(address(this));
    }

    function balanceOfAsset() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function balanceOfFToken() public view returns (uint256) {
        return ERC20(fToken).balanceOf(address(this));
    }

    function totalInvestment() public view returns (uint256) {
        return IFToken(fToken).convertToAssets(balanceOfFToken());
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    //////// EXTERNAL
    function _emergencyWithdraw(uint256 _amount) internal virtual override {
        _freeFunds(_min(_amount, IFToken(fToken).maxWithdraw(address(this))));
    }
}
