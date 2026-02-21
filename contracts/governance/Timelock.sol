// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    uint256 public constant MIN_DELAY = 2 days;
    
    constructor(address admin) TimelockController(MIN_DELAY, new address[](0), new address[](0), admin) {
    }
}
