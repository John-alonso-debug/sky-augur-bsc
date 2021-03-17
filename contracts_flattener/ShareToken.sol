pragma solidity 0.5.16;

contract IAugurLite {
  function isKnownUniverse(IUniverse _universe) public view returns (bool);
  function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public returns (bool);
  function logMarketCreated(
    bytes32 _topic,
    string memory _description,
    string memory _extraInfo,
    IUniverse _universe,
    address _market,
    address _marketCreator,
    bytes32[] memory _outcomes,
    int256 _minPrice,
    int256 _maxPrice,
    IMarket.MarketType _marketType) public returns (bool);
  function logMarketCreated(
    bytes32 _topic,
    string memory _description,
    string memory _extraInfo,
    IUniverse _universe,
    address _market,
    address _marketCreator,
    int256 _minPrice,
    int256 _maxPrice,
    IMarket.MarketType _marketType) public returns (bool);
  function logMarketResolved(IUniverse _universe) public returns (bool);

  function logShareTokensCreated(IShareToken[] memory _shareTokens, address _market) public returns (bool);
  function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
  function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public returns (bool);
  function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public returns (bool);
  function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool);
  function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
  function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool);
  function logTimestampSet(uint256 _newTimestamp) public returns (bool);
  function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool);
  function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool);
  function logEscapeHatchChanged(bool _isOn) public returns (bool);
}

contract IControlled {
  function getController() public view returns (IController);
  function setController(IController _controller) public returns(bool);
}

contract Controlled is IControlled {
  IController internal controller;

  constructor() public {
    controller = IController(msg.sender);
  }

  modifier onlyWhitelistedCallers {
    require(controller.assertIsWhitelisted(msg.sender), "Sender is not whitelisted");
    _;
  }

  modifier onlyCaller(bytes32 _key) {
    require(msg.sender == controller.lookup(_key), "Sender is not the contract");
    _;
  }

  modifier onlyControllerCaller {
    require(IController(msg.sender) == controller, "Sender is not the controller");
    _;
  }

  modifier onlyInGoodTimes {
    require(controller.stopInEmergency(), "Emergency stop is activate");
    _;
  }

  modifier onlyInBadTimes {
    require(controller.onlyInEmergency(), "Emergency stop is not activate");
    _;
  }

  function getController() public view returns(IController) {
    return controller;
  }

  function setController(IController _controller) public onlyControllerCaller returns(bool) {
    controller = _controller;
    return true;
  }
}

contract IController {
  function assertIsWhitelisted(address _target) public view returns(bool);
  function lookup(bytes32 _key) public view returns(address);
  function stopInEmergency() public view returns(bool);
  function onlyInEmergency() public view returns(bool);
  function getAugurLite() public view returns (IAugurLite);
  function getTimestamp() public view returns (uint256);
  function emergencyStop() public returns (bool);
}

contract IMailbox {
  function initialize(address _owner, IMarket _market) public returns (bool);
}

contract DelegationTarget is Controlled {
  bytes32 public controllerLookupName;
}

contract IOwnable {
  function getOwner() public view returns (address);
  function transferOwnership(address newOwner) public returns (bool);
}

contract ITyped {
  function getTypeName() public view returns (bytes32);
}

contract IMarket is ITyped, IOwnable {
  enum MarketType {
    YES_NO,
    CATEGORICAL,
    SCALAR
  }

  function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _oracle, address _creator, uint256 _numOutcomes, uint256 _numTicks) public returns (IShareToken[] memory _shareToken);
  function getUniverse() public view returns (IUniverse);
  function getNumberOfOutcomes() public view returns (uint256);
  function getNumTicks() public view returns (uint256);
  function getDenominationToken() public view returns (ERC20);
  function getShareToken(uint256 _outcome)  public view returns (IShareToken);
  function getMarketCreatorSettlementFeeDivisor() public view returns (uint256);
  function getEndTime() public view returns (uint256);
  function getMarketCreatorMailbox() public view returns (IMailbox);
  function getPayoutNumerator(uint256 _outcome) public view returns (uint256);
  function getResolutionTime() public view returns (uint256);
  function getOracle() public view returns (address);
  function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
  function isInvalid() public view returns (bool);
  function isResolved() public view returns (bool);
  function assertBalances() public view returns (bool);
}

contract IUniverse is ITyped {
  function initialize(ERC20 _denominationToken) external returns (bool);
  function getDenominationToken() public view returns (ERC20);
  function isContainerForMarket(IMarket _shadyTarget) public view returns (bool);
  function isContainerForShareToken(IShareToken _shadyTarget) public view returns (bool);
}

contract Initializable {
  bool private initialized = false;

  modifier afterInitialized {
    require(initialized, "The contract is not initialized");
    _;
  }

  modifier beforeInitialized {
    require(!initialized, "The contract is already initialized");
    _;
  }

  function endInitialization() internal beforeInitialized returns (bool) {
    initialized = true;
    return true;
  }

  function getInitialized() public view returns (bool) {
    return initialized;
  }
}

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

contract IShareToken is ITyped, ERC20 {
  function initialize(IMarket _market, uint256 _outcome) external returns (bool);
  function createShares(address _owner, uint256 _amount) external returns (bool);
  function destroyShares(address, uint256 balance) external returns (bool);
  function getMarket() external view returns (IMarket);
  function getOutcome() external view returns (uint256);
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

contract ShareToken is DelegationTarget, ITyped, Initializable, VariableSupplyToken, IShareToken {

  string constant public name = "Shares";
  uint8 constant public decimals = 0;
  string constant public symbol = "SHARE";

  IMarket private market;
  uint256 private outcome;

  function initialize(IMarket _market, uint256 _outcome) external beforeInitialized returns(bool) {
    endInitialization();
    market = _market;
    outcome = _outcome;
    return true;
  }

  function createShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    mint(_owner, _fxpValue);
    return true;
  }

  function destroyShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    burn(_owner, _fxpValue);
    return true;
  }

  function getTypeName() public view returns(bytes32) {
    return "ShareToken";
  }

  function getMarket() external view returns(IMarket) {
    return market;
  }

  function getOutcome() external view returns(uint256) {
    return outcome;
  }

  function onTokenTransfer(address _from, address _to, uint256 _value) internal returns (bool) {
    controller.getAugurLite().logShareTokensTransferred(market.getUniverse(), _from, _to, _value);
    return true;
  }

  function onMint(address _target, uint256 _amount) internal returns (bool) {
    controller.getAugurLite().logShareTokenMinted(market.getUniverse(), _target, _amount);
    return true;
  }

  function onBurn(address _target, uint256 _amount) internal returns (bool) {
    controller.getAugurLite().logShareTokenBurned(market.getUniverse(), _target, _amount);
    return true;
  }
}

