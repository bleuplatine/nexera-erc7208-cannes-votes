// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IBadgeManager {
    function issueBadge(address recipient) external;
    function getBadgeId(address recipient) external view returns (uint256);
}
