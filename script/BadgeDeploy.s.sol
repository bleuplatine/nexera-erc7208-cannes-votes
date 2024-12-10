// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {DataPointRegistry} from "../src/DataPointRegistry.sol";
import {DataIndex} from "../src/DataIndex.sol";
import {BadgeDataObject} from "../src/dataobjects/BadgeDataObject.sol";
import {BadgeDataManager} from "../src/datamanagers/BadgeDataManager.sol";
import {DataPoint} from "../src/utils/DataPoints.sol";

contract BadgeDeploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy core infrastructure
        DataPointRegistry dataPointRegistry = new DataPointRegistry();
        DataIndex dataIndex = new DataIndex();

        // 2. Deploy DataObject
        BadgeDataObject badgeDataObject = new BadgeDataObject();

        // 3. Allocate DataPoint from Registry
        DataPoint badgeDataPoint = dataPointRegistry.allocate(deployer);

        // 4. Configure DataObject
        badgeDataObject.setDataIndexImplementation(badgeDataPoint, dataIndex);

        // 5. Deploy and configure DataManager
        BadgeDataManager badgeDataManager = new BadgeDataManager(address(badgeDataObject), address(dataIndex), badgeDataPoint);

        // 6. Grant Admin Roles
        badgeDataManager.grantRole(badgeDataManager.BADGE_ADMIN_ROLE(), deployer);

        // 7. Approve DataManager in DataIndex
        dataIndex.allowDataManager(badgeDataPoint, address(badgeDataManager), true);

        vm.stopBroadcast();
    }
}
