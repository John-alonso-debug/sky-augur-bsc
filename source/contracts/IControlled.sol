pragma solidity 0.5.16;

import 'IController.sol';
import 'libraries/token/ERC20Basic.sol';


contract IControlled {
  function getController() public view returns (IController);
  function setController(IController _controller) public returns(bool);
}
