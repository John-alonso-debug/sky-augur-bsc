pragma solidity 0.5.16;

import 'libraries/IOwnable.sol';


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is IOwnable {
  address internal owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Sender is not the owner");
    _;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner returns (bool) {
    if (_newOwner != address(0)) {
      onTransferOwnership(owner, _newOwner);
      owner = _newOwner;
    }
    return true;
  }

  // Subclasses of this token may want to send additional logs through the centralized AugurLite log emitter contract
  function onTransferOwnership(address, address) internal returns (bool);
}
