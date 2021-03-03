pragma solidity 0.5.16;

library SafeMathUint256 {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    require(a == 0 || c / a == b, "Multiplication failed");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "Divisor should at least be 0");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "Subtraction yields negative value");
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "Addition failed");
    return c;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a >= b) {
      return a;
    } else {
      return b;
    }
  }

  function getUint256Min() internal pure returns (uint256) {
    return 0;
  }

  function getUint256Max() internal pure returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }

  function isMultipleOf(uint256 a, uint256 b) internal pure returns (bool) {
    return a % b == 0;
  }
}

contract ERC20Basic {
  event Transfer(address indexed from, address indexed to, uint256 value);

  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function totalSupply() public view returns (uint256);
}

contract BasicToken is ERC20Basic {
  using SafeMathUint256 for uint256;

  uint256 internal supply;
  mapping(address => uint256) internal balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns(bool) {
    return internalTransfer(msg.sender, _to, _value);
  }

  /**
  * @dev allows internal token transfers
  * @param _from The source address
  * @param _to The destination address
  */
  function internalTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    onTokenTransfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function totalSupply() public view returns (uint256) {
    return supply;
  }

  // Subclasses of this token generally want to send additional logs through the centralized AugurLite log emitter contract
  function onTokenTransfer(address _from, address _to, uint256 _value) internal returns (bool);
}

