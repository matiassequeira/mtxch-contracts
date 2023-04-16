// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

// Don't change the order of state for working upgrades.
// AND BE AWARE OF INHERITANCE VARIABLES!
// Inherited contracts contain storage slots and must be accounted for in any upgrades
// always test an exact upgrade on testnet and localhost before mainnet upgrades.
interface Peggy {
    function sendToInjective(
        address _tokenContract,
        bytes32 _destination,
        uint256 _amount,
        string calldata _data
    ) external;
}