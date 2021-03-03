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

contract ERC20 is ERC20Basic {
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
}

contract StandardToken is ERC20, BasicToken {
  using SafeMathUint256 for uint256;

  // Approvals of this amount are simply considered an everlasting approval which is not decremented when transfers occur
  uint256 public constant ETERNAL_APPROVAL_VALUE = 2 ** 256 - 1;

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
  * @dev Transfer tokens from one address to another
  * @param _from address The address which you want to send tokens from
  * @param _to address The address which you want to transfer to
  * @param _value uint256 the amout of tokens to be transfered
  */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];

    if (_allowance != ETERNAL_APPROVAL_VALUE) {
      allowed[_from][msg.sender] = _allowance.sub(_value);
    }
    internalTransfer(_from, _to, _value);
    return true;
  }

  /**
  * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
  * @param _spender The address which will spend the funds.
  * @param _value The amount of tokens to be spent.
  */
  function approve(address _spender, uint256 _value) public returns (bool) {
    approveInternal(msg.sender, _spender, _value);
    return true;
  }

  /**
  * @dev Function to check the amount of tokens that an owner allowed to a spender.
  * @param _owner address The address which owns the funds.
  * @param _spender address The address which will spend the funds.
  * @return A uint256 specifing the amount of tokens still avaible for the spender.
  */
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Increase the amount of tokens that an owner allowed to a spender.
  *
  * Approve should be called when allowed[_spender] == 0. To increment allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
  * @param _spender The address which will spend the funds.
  * @param _addedValue The amount of tokens to increase the allowance by.
  */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    approveInternal(msg.sender, _spender, allowed[msg.sender][_spender].add(_addedValue));
    return true;
  }

  /**
  * @dev Decrease the amount of tokens that an owner allowed to a spender.
  *
  * approve should be called when allowed[_spender] == 0. To decrement allowed value is better to use this function to avoid 2 calls (and wait until the first transaction is mined)
  * @param _spender The address which will spend the funds.
  * @param _subtractedValue The amount of tokens to decrease the allowance by.
  */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      approveInternal(msg.sender, _spender, 0);
    } else {
      approveInternal(msg.sender, _spender, oldValue.sub(_subtractedValue));
    }
    return true;
  }

  function approveInternal(address _owner, address _spender, uint256 _value) internal returns (bool) {
    allowed[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
    return true;
  }
}

contract VariableSupplyToken is StandardToken {
  using SafeMathUint256 for uint256;

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
  function onMint(address, uint256) internal returns (bool);

  // Subclasses of this token may want to send additional logs through the centralized AugurLite log emitter contract
  function onBurn(address, uint256) internal returns (bool);
}

