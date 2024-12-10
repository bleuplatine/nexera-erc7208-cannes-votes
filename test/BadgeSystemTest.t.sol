// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BadgeDataManager} from "../src/datamanagers/BadgeDataManager.sol";
import {BadgeDataObject} from "../src/dataobjects/BadgeDataObject.sol";
import {IBadgeDataManager} from "../src/interfaces/IBadgeDataManager.sol";
import {DataPoint, DataPoints} from "../src/utils/DataPoints.sol";
import {DataPointRegistry} from "../src/DataPointRegistry.sol";
import {DataIndex} from "../src/DataIndex.sol";
import {IDataIndex} from "../src/interfaces/IDataIndex.sol";
import {IDataObject} from "../src/interfaces/IDataObject.sol";
import {IDataPointRegistry} from "../src/interfaces/IDataPointRegistry.sol";

contract BadgeSystemTest is Test {
    DataPointRegistry public registry;
    DataIndex public dataIndex;
    BadgeDataObject public badgeStorage;
    BadgeDataManager public manager;
    DataPoint public badgeDataPoint;

    address public admin = makeAddr("admin");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    function setUp() public {
        vm.startPrank(admin);

        registry = new DataPointRegistry();
        dataIndex = new DataIndex();
        badgeStorage = new BadgeDataObject();
        badgeDataPoint = registry.allocate(admin);
        
        badgeStorage.setDataIndexImplementation(badgeDataPoint, dataIndex);
        
        manager = new BadgeDataManager(
            address(badgeStorage),
            address(dataIndex),
            badgeDataPoint
        );

        dataIndex.allowDataManager(badgeDataPoint, address(manager), true);

        vm.stopPrank();
    }

    function testBadgeSystem() public {
        vm.startPrank(admin);

        // Issue badges
        manager.issueBadge(user1);
        manager.issueBadge(user2);

        // Check badge IDs
        uint256 badge1 = manager.getBadgeId(user1);
        uint256 badge2 = manager.getBadgeId(user2);

        // Assert sequential badge IDs starting at 100
        assertEq(badge1, 101);
        assertEq(badge2, 102);

        vm.stopPrank();
    }
}