pragma solidity 0.5.16;

import 'IMarket.sol';
import 'IShareToken.sol';
import 'libraries/ITyped.sol';
import 'libraries/token/IBEP20.sol';


contract IUniverse is ITyped {
  function initialize(address _denominationToken) external returns (bool);
  function getDenominationToken() public view returns (IBEP20);
  function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
}
