// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

import {FluidLender} from "./FluidLender.sol";
import {IStrategyInterface} from "./interfaces/IStrategyInterface.sol";

contract FluidLenderFactory {
    event NewFluidLender(address indexed strategy, address indexed asset);

    address public management;
    address public performanceFeeRecipient;
    address public keeper;
    address public emergencyAdmin;

    /// @notice Track the deployments. asset => strategy
    mapping(address => address) public deployments;

    constructor(
        address _management,
        address _performanceFeeRecipient,
        address _keeper,
        address _emergencyAdmin
    ) {
        require(_management != address(0), "ZERO ADDRESS");
        management = _management;
        performanceFeeRecipient = _performanceFeeRecipient;
        keeper = _keeper;
        emergencyAdmin = _emergencyAdmin;
    }

    /**
     * @notice Deploy a new Fluid Lender.
     * @dev This will set the msg.sender to all of the permissioned roles.
     * @param _asset The underlying asset for the lender to use.
     * @param _name The name for the lender to use.
     * @return . The address of the new lender.
     */
    function newFluidLender(address _asset, address _fToken, string memory _name) external returns (address) {
        IStrategyInterface newStrategy = IStrategyInterface(
            address(
                new FluidLender(
                    _asset,
                    _fToken,
                    _name
                )
            )
        );

        newStrategy.setPerformanceFeeRecipient(performanceFeeRecipient);

        newStrategy.setKeeper(keeper);

        newStrategy.setEmergencyAdmin(emergencyAdmin);

        newStrategy.setPendingManagement(management);

        emit NewFluidLender(address(newStrategy), _asset);

        deployments[_asset] = address(newStrategy);
        return address(newStrategy);
    }

    function setAddresses(
        address _management,
        address _performanceFeeRecipient,
        address _keeper,
        address _emergencyAdmin
    ) external {
        require(msg.sender == management, "!management");
        management = _management;
        performanceFeeRecipient = _performanceFeeRecipient;
        keeper = _keeper;
        emergencyAdmin = _emergencyAdmin;
    }

    function isDeployedStrategy(
        address _strategy
    ) external view returns (bool) {
        address asset = IStrategyInterface(_strategy).asset();
        return deployments[asset] == _strategy;
    }
}
