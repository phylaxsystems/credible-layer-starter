// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GasSpender {
    address private _owner;
    uint256 public result;
    uint256 public assertionCounter;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function triggerAssertion(uint256 txFactor, uint256 _assertionCounter) external {
        uint256 tmp = 0;
        for(uint256 i = 0; i < txFactor; i++) {
            tmp++;
        }
        result = tmp;
        assertionCounter = _assertionCounter;
    }
}