pragma solidity 0.5.16;

contract Initializable {
  bool private initialized = false;

  modifier afterInitialized {
    require(initialized, "The contract is not initialized");
    _;
  }

  modifier beforeInitialized {
    require(!initialized, "The contract is already initialized");
    _;
  }

  function endInitialization() internal beforeInitialized returns (bool) {
    initialized = true;
    return true;
  }

  function getInitialized() public view returns (bool) {
    return initialized;
  }
}

