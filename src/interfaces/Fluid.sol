// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

interface IFToken {
    function asset() external view returns (address);
    function deposit(uint256 _amount, address _receiver) external returns (uint256 _shares);
    function redeem(uint256 _shares, address, address) external;
    function convertToShares(uint256) external view returns (uint256);
    function convertToAssets(uint256) external view returns (uint256);
    function maxRedeem(address _owner) external view returns (uint256);
    function maxDeposit(address _owner) external view returns (uint256);
    function maxWithdraw(address _owner) external view returns (uint256);
    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);
}

interface IStaking {
    function stakingToken() external view returns (address);
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function getReward() external;
    function rewardsToken() external view returns (address);
}