// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IDataObject} from "../interfaces/IDataObject.sol";
import {IDataIndex} from "../interfaces/IDataIndex.sol";
import {IDataPointRegistry} from "../interfaces/IDataPointRegistry.sol";
import {IBadgeManager} from "../interfaces/IBadgeManager.sol";
import {DataPoints, DataPoint} from "../utils/DataPoints.sol";
import {ChainidTools} from "../utils/ChainidTools.sol";

contract BadgeDataObject is IDataObject {
    struct BadgeDPStorage {
        IDataIndex dataIndexImplementation;
        mapping(bytes32 => uint256) badges;
        uint256 nextBadgeId;
    }

    mapping(DataPoint => BadgeDPStorage) private _badgeDPStorage;

    error InvalidCaller(DataPoint dp, address sender);
    error UninitializedDataPoint(DataPoint dp);
    error UnsupportedOperation();

    event DataIndexImplementationSet(DataPoint dp, address impl);

    modifier onlyDataIndex(DataPoint dp) {
        BadgeDPStorage storage bdps = _dataPointStorage(dp);
        if (address(bdps.dataIndexImplementation) != msg.sender) revert InvalidCaller(dp, msg.sender);
        _;
    }

    constructor() {
        _badgeDPStorage[DataPoint.wrap(0)].nextBadgeId = 100; // Start at 101
    }

    /// @inheritdoc IDataObject
    function read(DataPoint dp, bytes4 operation, bytes calldata data) external view returns (bytes memory) {
        BadgeDPStorage storage bdps = _badgeDPStorage[dp];

        if (operation == IBadgeManager.getBadgeId.selector) {
            address holder = abi.decode(data, (address));
            bytes32 diid = _diid(dp, holder);
            return abi.encode(bdps.badges[diid]);
        }

        revert UnsupportedOperation();
    }

    /// @inheritdoc IDataObject
    function write(DataPoint dp, bytes4 operation, bytes calldata data)
        external
        onlyDataIndex(dp)
        returns (bytes memory)
    {
        BadgeDPStorage storage bdps = _badgeDPStorage[dp];

        if (operation == IBadgeManager.issueBadge.selector) {
            address recipient = abi.decode(data, (address));
            bytes32 diid = _diid(dp, recipient);

            if (bdps.nextBadgeId == 0) {
                bdps.nextBadgeId = 100; // Start at 101
            }

            bdps.nextBadgeId++;
            bdps.badges[diid] = bdps.nextBadgeId;
            return "";
        }

        revert UnsupportedOperation();
    }

    /// @inheritdoc IDataObject
    function setDataIndexImplementation(DataPoint dp, IDataIndex newImpl) external {
        // Registering new DataPoint
        // Should be called by DataPoint Admin
        if (!_isDataPointAdmin(dp, msg.sender)) revert InvalidCaller(dp, msg.sender);

        BadgeDPStorage storage bdps = _badgeDPStorage[dp];

        bdps.dataIndexImplementation = newImpl;
        emit DataIndexImplementationSet(dp, address(newImpl));
    }

    // =========== Helper functions ============

    function _isDataPointAdmin(DataPoint dp, address account) internal view returns (bool) {
        (uint32 chainId, address registry,) = DataPoints.decode(dp);
        ChainidTools.requireCurrentChain(chainId);
        return IDataPointRegistry(registry).isAdmin(dp, account);
    }

    function _diid(DataPoint dp, address account) internal view returns (bytes32) {
        BadgeDPStorage storage bdps = _dataPointStorage(dp);
        return bdps.dataIndexImplementation.diid(account, dp);
    }

    function _dataPointStorage(DataPoint dp) private view returns (BadgeDPStorage storage) {
        BadgeDPStorage storage bdps = _badgeDPStorage[dp];
        if (address(bdps.dataIndexImplementation) == address(0)) revert UninitializedDataPoint(dp);
        return _badgeDPStorage[dp];
    }
}
