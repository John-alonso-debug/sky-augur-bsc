pragma solidity 0.5.16;

import 'IMarket.sol';


contract IMailbox {
  function initialize(address _owner, IMarket _market) public returns (bool);
}
