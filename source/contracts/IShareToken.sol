pragma solidity 0.5.16;

import 'IMarket.sol';
import 'libraries/ITyped.sol';
import 'libraries/token/ERC20.sol';


contract IShareToken is ITyped, ERC20 {
  function initialize(IMarket _market, uint256 _outcome) external returns (bool);
  function createShares(address _owner, uint256 _amount) external returns (bool);
  function destroyShares(address, uint256 balance) external returns (bool);
  function getMarket() external view returns (IMarket);
  function getOutcome() external view returns (uint256);
}
