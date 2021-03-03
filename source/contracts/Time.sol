pragma solidity 0.5.16;

import 'ITime.sol';


contract Time is ITime {
  function getTimestamp() external view returns (uint256) {
    return block.timestamp;
  }

  function getTypeName() public view returns (bytes32) {
    return "Time";
  }
}
