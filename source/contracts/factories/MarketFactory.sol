pragma solidity 0.5.16;

import 'IMarket.sol';
import 'IController.sol';
import 'libraries/Delegator.sol';
import 'libraries/token/BEP20.sol';
import 'IShareToken.sol';
import 'Controlled.sol';


contract MarketFactory {
  function createMarket(IController _controller, IUniverse _universe, uint256 _endTime, uint256 _feeDivisor, BEP20 _denominationToken, address _oracle, address _sender, uint256 _numOutcomes, uint256 _numTicks) public returns (IMarket _market) {
    Delegator _delegator = new Delegator(_controller, "Market");
    _market = IMarket(address(_delegator));
    IShareToken[] memory _shareTokens =_market.initialize(_universe, _endTime, _feeDivisor, _denominationToken, _oracle, _sender, _numOutcomes, _numTicks);
    _controller.getAugurLite().logShareTokensCreated(_shareTokens,address(_market));
    return _market;
  }
}
