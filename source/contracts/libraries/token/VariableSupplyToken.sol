pragma solidity 0.5.16;

import 'libraries/token/StandardToken.sol';

//import 'libraries/token/SafeMath.sol';
contract VariableSupplyToken is StandardToken {
  using SafeMath for uint256;

  event Mint(address indexed target, uint256 value);
  event Burn(address indexed target, uint256 value);

  /**
  * @dev mint tokens for a specified address
  * @param _target The address to mint tokens for.
  * @param _amount The amount to be minted.
  */
  function mint(address _target, uint256 _amount) internal returns (bool) {
    balances[_target] = balances[_target].add(_amount);
    supply = supply.add(_amount);
    emit Mint(_target, _amount);
    emit Transfer(address(0), _target, _amount);
    onMint(_target, _amount);
    return true;
  }

  /**
  * @dev burn tokens belonging to a specified address
  * @param _target The address to burn tokens for.
  * @param _amount The amount to be burned.
  */
  function burn(address _target, uint256 _amount) internal returns (bool) {
    balances[_target] = balances[_target].sub(_amount);
    supply = supply.sub(_amount);
    emit Burn(_target, _amount);
    emit Transfer(_target, address(0), _amount);
    onBurn(_target, _amount);
    return true;
  }

  // Subclasses of this token may want to send additional logs through the centralized AugurLite log emitter contract
  function onMint(address, uint256)  internal  returns (bool);

  // Subclasses of this token may want to send additional logs through the centralized AugurLite log emitter contract
  function onBurn(address, uint256) internal  returns (bool);
}
