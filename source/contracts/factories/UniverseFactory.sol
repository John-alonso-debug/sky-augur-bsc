pragma solidity 0.5.16;

import 'IController.sol';
import 'IUniverse.sol';
import 'libraries/Delegator.sol';
import 'libraries/token/IBEP20.sol';



contract UniverseFactory {

  function createUniverse(IController _controller, address _denominationToken) public returns (IUniverse) {

    //TODO: Fix Error: Explicit type conversion not allowed from "contract Delegator" to "contract IUniverse".
    Delegator _delegator = new Delegator(_controller, "Universe");
    IUniverse _universe = IUniverse(address(_delegator));

    _universe.initialize(_denominationToken);
    return _universe;
  }
}
