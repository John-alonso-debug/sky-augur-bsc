pragma solidity ^0.4.26;

import 'IControlled.sol';
import 'IController.sol';
import 'libraries/token/BEP20Basic.sol';


contract ControllerUser is IControlled {
  address public updatedController;

  function getController() public view returns (IController) {
    return IController(0);
  }

  function setController(IController _controller) public returns(bool) {
    updatedController = _controller;
    return true;
  }
}
