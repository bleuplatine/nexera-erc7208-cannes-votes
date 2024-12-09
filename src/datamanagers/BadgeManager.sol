// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IDataObject} from "../interfaces/IDataObject.sol";
import {IDataIndex} from "../interfaces/IDataIndex.sol";
import {IBadgeManager} from "../interfaces/IBadgeManager.sol";
import {DataPoint} from "../utils/DataPoints.sol";

contract BadgeManager is IBadgeManager, AccessControl {
    bytes32 public constant BADGE_ADMIN_ROLE = keccak256("BADGE_ADMIN_ROLE");
    
    IDataObject public immutable badgeStorage;
    IDataIndex public immutable dataIndex;
    DataPoint public immutable badgeDataPoint;

    constructor(
        address _badgeStorage,
        address _dataIndex,
        DataPoint _badgeDataPoint
    ) {
        badgeStorage = IDataObject(_badgeStorage);
        dataIndex = IDataIndex(_dataIndex);
        badgeDataPoint = _badgeDataPoint;
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BADGE_ADMIN_ROLE, msg.sender);
    }

    function issueBadge(address recipient) external onlyRole(BADGE_ADMIN_ROLE) {
        dataIndex.write(
            address(badgeStorage),
            badgeDataPoint,
            IBadgeManager.issueBadge.selector,
            abi.encode(recipient)
        );
    }

    function getBadgeId(address recipient) external view returns (uint256) {
        bytes memory result = dataIndex.read(
            address(badgeStorage),
            badgeDataPoint,
            IBadgeManager.getBadgeId.selector,
            abi.encode(recipient)
        );
        return abi.decode(result, (uint256));
    }
}