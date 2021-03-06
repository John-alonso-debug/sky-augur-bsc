pragma solidity 0.5.16;

import 'IMarket.sol';
import 'IController.sol';
import 'libraries/Delegator.sol';


contract ShareTokenFactory {
  function createShareToken(IController _controller, IMarket _market, uint256 _outcome) public returns (IShareToken) {
    Delegator _delegator = new Delegator(_controller, "ShareToken");
    IShareToken _shareToken = IShareToken(address(_delegator));
    _shareToken.initialize(_market, _outcome);
    return _shareToken;
  }
}
