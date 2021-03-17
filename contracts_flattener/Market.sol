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

contract MailboxFactory {
  function createMailbox(IController _controller, address _owner, IMarket _market) public returns (IMailbox) {
    Delegator _delegator = new Delegator(_controller, "Mailbox");
    IMailbox _mailbox = IMailbox(address(_delegator));
    _mailbox.initialize(_owner, _market);
    return _mailbox;
  }
}

contract ShareTokenFactory {
  function createShareToken(IController _controller, IMarket _market, uint256 _outcome) public returns (IShareToken) {
    Delegator _delegator = new Delegator(_controller, "ShareToken");
    IShareToken _shareToken = IShareToken(address(_delegator));
    _shareToken.initialize(_market, _outcome);
    return _shareToken;
  }
}

contract DelegationTarget is Controlled {
  bytes32 public controllerLookupName;
}

contract Delegator is DelegationTarget {
  //  TODO: Fix Error: Explicit type conversion not allowed from "contract Delegator" to "contract IUniverse".
  //  I did nothing
  constructor(IController _controller, bytes32 _controllerLookupName) public {
    controller = _controller;
    controllerLookupName = _controllerLookupName;
  }

  function() external payable {
    // Do nothing if we haven't properly set up the delegator to delegate calls
    if (controllerLookupName == 0) {
      return;
    }

    // Get the delegation target contract
    address _target = controller.lookup(controllerLookupName);

    assembly {
    //0x40 is the address where the next free memory slot is stored in Solidity
      let _calldataMemoryOffset := mload(0x40)
    // new "memory end" including padding. The bitwise operations here ensure we get rounded up to the nearest 32 byte boundary
      let _size := and(add(calldatasize, 0x1f), not(0x1f))
    // Update the pointer at 0x40 to point at new free memory location so any theoretical allocation doesn't stomp our memory in this call
      mstore(0x40, add(_calldataMemoryOffset, _size))
    // Copy method signature and parameters of this call into memory
      calldatacopy(_calldataMemoryOffset, 0x0, calldatasize)
    // Call the actual method via delegation
      let _retval := delegatecall(gas, _target, _calldataMemoryOffset, calldatasize, 0, 0)
      switch _retval
      case 0 {
      // 0 == it threw, so we revert
        revert(0, 0)
      } default {
      // If the call succeeded return the return data from the delegate call
        let _returndataMemoryOffset := mload(0x40)
      // Update the pointer at 0x40 again to point at new free memory location so any theoretical allocation doesn't stomp our memory in this call
        mstore(0x40, add(_returndataMemoryOffset, returndatasize))
        returndatacopy(_returndataMemoryOffset, 0x0, returndatasize)
        return (_returndataMemoryOffset, returndatasize)
      }
    }
  }
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

contract Ownable is IOwnable {
  address internal owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Sender is not the owner");
    _;
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner returns (bool) {
    if (_newOwner != address(0)) {
      onTransferOwnership(owner, _newOwner);
      owner = _newOwner;
    }
    return true;
  }

  // Subclasses of this token may want to send additional logs through the centralized AugurLite log emitter contract
  function onTransferOwnership(address, address) internal returns (bool);
}

contract Market is DelegationTarget, ITyped, Initializable, Ownable, IMarket {
  using SafeMathUint256 for uint256;
  using SafeMathInt256 for int256;

  // Constants
  uint256 private constant MIN_FEE_DIVISOR = 2; // Corresponds to 50% fee
  uint256 private constant APPROVAL_AMOUNT = 2 ** 256 - 1;
  address private constant NULL_ADDRESS = address(0);
  uint256 private constant MIN_OUTCOMES = 2;
  uint256 private constant MAX_OUTCOMES = 8;

  // Contract Refs
  IUniverse private universe;
  ERC20 private denominationToken;

  // Attributes
  uint256 private numTicks;
  uint256 private feeDivisor;
  uint256 private endTime;
  uint256 private numOutcomes;
  uint256 private resolutionTime;
  address private oracle;
  bool private invalid;
  IMailbox private marketCreatorMailbox;
  uint256[] private payoutNumerators;
  IShareToken[] private shareTokens;

  function initialize(IUniverse _universe, uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken,
    address _oracle, address _creator, uint256 _numOutcomes, uint256 _numTicks) public onlyInGoodTimes beforeInitialized returns (IShareToken[] memory _shareToken) {
    endInitialization();
    require(MIN_OUTCOMES <= _numOutcomes && _numOutcomes <= MAX_OUTCOMES, "Invalid number of outcomes");
    require(_numTicks > 0, "numTicks needs to be greater than 0");
    require(_oracle != NULL_ADDRESS, "Oracle cannot be the 0x0 address");
    require((_numTicks >= _numOutcomes), "numTicks needs to be greater than number of outcomes");
    require(_feeDivisor == 0 || _feeDivisor >= MIN_FEE_DIVISOR, "Invalid feeDivisor");
    require(_creator != NULL_ADDRESS, "Market creator cannot be the 0x0 address");
    require(controller.getTimestamp() < _endTime, "Market expiration is in the past");
    require(IUniverse(_universe).getDenominationToken() == _denominationToken, "Market denominationToken does not match the universe denominationToken");

    universe = _universe;
    owner = _creator;
    endTime = _endTime;
    numOutcomes = _numOutcomes;
    numTicks = _numTicks;
    feeDivisor = _feeDivisor;
    denominationToken = _denominationToken;
    oracle = _oracle;
    marketCreatorMailbox = MailboxFactory(controller.lookup("MailboxFactory")).createMailbox(controller, owner, this);
    for (uint256 _outcome = 0; _outcome < numOutcomes; _outcome++) {
      shareTokens.push(createShareToken(_outcome));
    }
    approveSpenders();
    return shareTokens;
  }

  function createShareToken(uint256 _outcome) private onlyInGoodTimes returns (IShareToken) {
    return ShareTokenFactory(controller.lookup("ShareTokenFactory")).createShareToken(controller, this, _outcome);
  }

  // This will need to be called manually for each open market if a spender contract is updated
  function approveSpenders() public onlyInGoodTimes returns (bool) {
    require(denominationToken.approve(controller.lookup("CompleteSets"), APPROVAL_AMOUNT), "Denomination token CompleteSets approval failed");
    require(denominationToken.approve(controller.lookup("ClaimTradingProceeds"), APPROVAL_AMOUNT), "Denomination token ClaimTradingProceeds approval failed");
    return true;
  }

  function resolve(uint256[] memory _payoutNumerators, bool _invalid) public onlyInGoodTimes returns (bool) {
    uint256 _timestamp = controller.getTimestamp();
    require(!isResolved(), "Market is already resolved");
    require(_timestamp > endTime, "Market is not expired");
    require(msg.sender == getOracle(), "Sender is not the oracle");
    require(verifyResolutionInformation(_payoutNumerators, _invalid), "Invalid payoutNumerators");

    resolutionTime = _timestamp;
    payoutNumerators = _payoutNumerators;
    invalid = _invalid;
    controller.getAugurLite().logMarketResolved(universe);
    return true;
  }

  function getMarketCreatorSettlementFeeDivisor() public view returns (uint256) {
    return feeDivisor;
  }

  function deriveMarketCreatorFeeAmount(uint256 _amount) public view returns (uint256) {
    if (feeDivisor == 0) {
      return 0;
    }
    return _amount / feeDivisor;
  }

  function withdrawInEmergency() public onlyInBadTimes onlyOwner returns (bool) {
    if (address(this).balance > 0) {
      msg.sender.transfer(address(this).balance);
    }
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "Market";
  }

  function isResolved() public view returns (bool) {
    return getResolutionTime() != 0;
  }

  function getEndTime() public view returns (uint256) {
    return endTime;
  }

  function getMarketCreatorMailbox() public view returns (IMailbox) {
    return marketCreatorMailbox;
  }

  function isInvalid() public view returns (bool) {
    require(isResolved(), "Market is not resolved");
    return invalid;
  }

  function getOracle() public view returns (address) {
    return address(oracle);
  }

  function getPayoutNumerator(uint256 _outcome) public view returns (uint256) {
    require(isResolved(), "Market is not resolved");
    return payoutNumerators[_outcome];
  }

  function getUniverse() public view returns (IUniverse) {
    return universe;
  }

  function getResolutionTime() public view returns (uint256) {
    return resolutionTime;
  }

  function getNumberOfOutcomes() public view returns (uint256) {
    return numOutcomes;
  }

  function getNumTicks() public view returns (uint256) {
    return numTicks;
  }

  function getDenominationToken() public view returns (ERC20) {
    return denominationToken;
  }

  function getShareToken(uint256 _outcome) public view returns (IShareToken) {
    return shareTokens[_outcome];
  }

  function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
    return getShareToken(_shadyShareToken.getOutcome()) == _shadyShareToken;
  }

  function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
    controller.getAugurLite().logMarketTransferred(getUniverse(), _owner, _newOwner);
    return true;
  }

  function verifyResolutionInformation(uint256[] memory _payoutNumerators, bool _invalid) public view returns (bool) {
    uint256 _sum = 0;
    uint256 _previousValue = _payoutNumerators[0];
    require(_payoutNumerators.length == numOutcomes, "payoutNumerators array is missing outcomes");
    for (uint256 i = 0; i < _payoutNumerators.length; i++) {
      uint256 _value = _payoutNumerators[i];
      _sum = _sum.add(_value);
      require(!_invalid || _value == _previousValue, "Wrong value in payoutNumerators for invalid market");
      _previousValue = _value;
    }
    if (_invalid) {
      require(_previousValue == numTicks / numOutcomes, "Wrong value in payoutNumerators for invalid market");
    } else {
      require(_sum == numTicks, "payoutNumerators array does not sum to numTicks");
    }
    return true;
  }

  function assertBalances() public view returns (bool) {
    // Escrowed funds for open orders
    uint256 _expectedBalance = 0;
    // Market Open Interest. If we're resolved we need actually calculate the value
    if (isResolved()) {
      for (uint256 i = 0; i < numOutcomes; i++) {
        _expectedBalance = _expectedBalance.add(shareTokens[i].totalSupply().mul(getPayoutNumerator(i)));
      }
    } else {
      _expectedBalance = _expectedBalance.add(shareTokens[0].totalSupply().mul(numTicks));
    }

    assert(denominationToken.balanceOf(address(this)) >= _expectedBalance);
    return true;
  }
}

library SafeMathInt256 {
  // Signed ints with n bits can range from -2**(n-1) to (2**(n-1) - 1)
  int256 private constant INT256_MIN = -2**(255);
  int256 private constant INT256_MAX = (2**(255) - 1);

  function mul(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a * b;
    require(a == 0 || c / a == b, "Multiplication failed");
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {
    // Solidity only automatically asserts when dividing by 0
    require(b != 0, "Divisor cannot be 0");
    int256 c = a / b;
    return c;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require(((a >= 0) && (b >= a - INT256_MAX)) || ((a < 0) && (b <= a - INT256_MIN)), "Subtraction failed");
    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    require(((a >= 0) && (b <= INT256_MAX - a)) || ((a < 0) && (b >= INT256_MIN - a)), "Addition failed");
    return a + b;
  }

  function min(int256 a, int256 b) internal pure returns (int256) {
    if (a <= b) {
      return a;
    } else {
      return b;
    }
  }

  function max(int256 a, int256 b) internal pure returns (int256) {
    if (a >= b) {
      return a;
    } else {
      return b;
    }
  }

  function getInt256Min() internal pure returns (int256) {
    return INT256_MIN;
  }

  function getInt256Max() internal pure returns (int256) {
    return INT256_MAX;
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

