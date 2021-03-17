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

contract MarketFactory {
  function createMarket(IController _controller, IUniverse _universe, uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, address _sender, uint256 _numOutcomes, uint256 _numTicks) public returns (IMarket _market) {
    Delegator _delegator = new Delegator(_controller, "Market");
    _market = IMarket(address(_delegator));
    IShareToken[] memory _shareTokens =_market.initialize(_universe, _endTime, _feeDivisor, _denominationToken, _oracle, _sender, _numOutcomes, _numTicks);
    _controller.getAugurLite().logShareTokensCreated(_shareTokens,address(_market));
    return _market;
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

contract Universe is DelegationTarget, Initializable, ITyped, IUniverse {
  using SafeMathUint256 for uint256;

  mapping(address => bool) private markets;
  ERC20 private denominationToken;

  function initialize(ERC20 _denominationToken) external onlyInGoodTimes beforeInitialized returns (bool) {
    endInitialization();
    denominationToken = _denominationToken;
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "Universe";
  }

  function isContainerForMarket(IMarket _shadyMarket) public view returns (bool) {
    return markets[address(_shadyMarket)];
  }

  function isContainerForShareToken(IShareToken _shadyShareToken) public view returns (bool) {
    IMarket _shadyMarket = _shadyShareToken.getMarket();
    if (address(_shadyMarket) == address(0)) {
      return false;
    }
    if (!isContainerForMarket(_shadyMarket)) {
      return false;
    }
    IMarket _legitMarket = _shadyMarket;
    return _legitMarket.isContainerForShareToken(_shadyShareToken);
  }

  function getDenominationToken() public view returns (ERC20) {
    return denominationToken;
  }
  //TODO:
  function createYesNoMarket(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, bytes32 _topic, string memory _description, string memory _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    _newMarket = createMarketInternal(
      _endTime,
        _feeDivisor,
        _denominationToken,
        _oracle,
        msg.sender,
        2,
        10000);
    controller.getAugurLite().logMarketCreated(
      _topic,
      _description,
      _extraInfo,
      this,
      address(_newMarket),
      msg.sender,
      0,
      1 ether,
      IMarket.MarketType.YES_NO);
    return _newMarket;
  }
  //TODO:
  function createCategoricalMarket(
    uint256 _endTime,
    uint256 _feeDivisor,
    ERC20 _denominationToken,
    address _oracle,
    bytes32[] memory _outcomes,
    bytes32 _topic,
    string memory _description,
    string memory _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    _newMarket = createMarketInternal(_endTime,
      _feeDivisor,
      _denominationToken,
      _oracle,
      msg.sender,
      uint256(_outcomes.length),
      10000);
   // IShareToken shareToken = _newMarket.getShareToken(_newMarket.getNumTicks());
    controller.getAugurLite().logMarketCreated(
    // shareToken,
      _topic,
        _description,
        _extraInfo,
        this,
        address(_newMarket),
        msg.sender,
        _outcomes,
        0,
        1 ether,
        IMarket.MarketType.CATEGORICAL);
    return _newMarket;
  }

  function createScalarMarket(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, int256 _minPrice, int256 _maxPrice, uint256 _numTicks, bytes32 _topic, string memory _description, string memory _extraInfo) public onlyInGoodTimes returns (IMarket _newMarket) {
    require(bytes(_description).length > 0, "Description is empty");
    require(_minPrice < _maxPrice, "Min price needs to be less than max price");
    require(_numTicks.isMultipleOf(2), "numTicks needs to a multiple of 2");
    _newMarket = createMarketInternal(_endTime, _feeDivisor, _denominationToken, _oracle, msg.sender, 2, _numTicks);
    controller.getAugurLite().logMarketCreated(_topic, _description, _extraInfo, this, address(_newMarket), msg.sender, _minPrice, _maxPrice, IMarket.MarketType.SCALAR);
    return _newMarket;
  }

  function createMarketInternal(uint256 _endTime, uint256 _feeDivisor, ERC20 _denominationToken, address _oracle, address _sender, uint256 _numOutcomes, uint256 _numTicks) private onlyInGoodTimes returns (IMarket _newMarket) {
    MarketFactory _marketFactory = MarketFactory(controller.lookup("MarketFactory"));
    _newMarket = _marketFactory.createMarket(controller, this,
      _endTime, _feeDivisor, _denominationToken, _oracle, _sender, _numOutcomes, _numTicks);
    markets[address(_newMarket)] = true;
    return _newMarket;
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

