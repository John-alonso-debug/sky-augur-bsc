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

  function initialize(IUniverse _universe, uint256 _endTime, uint256 _feePerEthInAttoeth, ERC20 _denominationToken, address _oracle, address _creator, uint256 _numOutcomes, uint256 _numTicks) public returns (bool _success);
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

contract MarketValidator is Controlled {
  modifier marketIsLegit(IMarket _market) {
    IUniverse _universe = _market.getUniverse();
    require(controller.getAugurLite().isKnownUniverse(_universe), "The universe is not known");
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    _;
  }
}

contract ReentrancyGuard {
  /**
   * @dev We use a single lock for the whole contract.
   */
  bool private rentrancyLock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also mark it `external`. Calling one nonReentrant function from another is not supported. Instead, you can implement a `private` function doing the actual work, and a `external` wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(!rentrancyLock, "Reentrancy lock is on");
    rentrancyLock = true;
    _;
    rentrancyLock = false;
  }
}

contract ClaimTradingProceeds is ReentrancyGuard, MarketValidator {
  using SafeMathUint256 for uint256;

  function claimTradingProceeds(IMarket _market, address _shareHolder) marketIsLegit(_market) onlyInGoodTimes nonReentrant external returns(bool) {
    // NOTE: this requirement does _not_ enforce market finalization. That requirement occurs later on in this function
    //when calling getPayoutNumerator. When this requirement is removed we may want to consider explicitly
    //requiring it here (or modifying this comment and keeping the gas savings)
    require(controller.getTimestamp() > _market.getResolutionTime(), "Resolution time is not in the past");

    ERC20 denominationToken = _market.getDenominationToken();

    for (uint256 _outcome = 0; _outcome < _market.getNumberOfOutcomes(); ++_outcome) {
      IShareToken _shareToken = _market.getShareToken(_outcome);
      uint256 _numberOfShares = _shareToken.balanceOf(_shareHolder);
      uint256 _proceeds;
      uint256 _shareHolderShare;
      uint256 _creatorShare;
      (_proceeds, _shareHolderShare, _creatorShare) = divideUpWinnings(_market, _outcome, _numberOfShares);

      // always destroy shares as it gives a minor gas refund and is good for the network
      if (_numberOfShares > 0) {
        _shareToken.destroyShares(_shareHolder, _numberOfShares);
       //TODO:
        logTradingProceedsClaimed(_market,address(_shareToken), _shareHolder, _numberOfShares, _shareHolderShare);
      }
      if (_shareHolderShare > 0) {
        require(denominationToken.transferFrom(address(_market), _shareHolder, _shareHolderShare), "Denomination token transfer failed");
      }
      if (_creatorShare > 0) {
        require(denominationToken.transferFrom(address(_market), address(_market.getMarketCreatorMailbox()), _creatorShare), "Denomination token transfer failed");
      }
    }

    _market.assertBalances();

    return true;
  }

  function logTradingProceedsClaimed(IMarket _market, address _shareToken, address _sender, uint256 _numShares, uint256 _numPayoutTokens) private returns (bool) {
    controller.getAugurLite().logTradingProceedsClaimed(_market.getUniverse(), _shareToken, _sender,address(_market), _numShares, _numPayoutTokens, _market.getDenominationToken().balanceOf(_sender).add(_numPayoutTokens));
    return true;
  }

  function divideUpWinnings(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256 _proceeds, uint256 _shareHolderShare, uint256 _creatorShare) {
    _proceeds = calculateProceeds(_market, _outcome, _numberOfShares);
    _creatorShare = calculateCreatorFee(_market, _proceeds);
    _shareHolderShare = _proceeds.sub(_creatorShare);
    return (_proceeds, _shareHolderShare, _creatorShare);
  }

  function calculateProceeds(IMarket _market, uint256 _outcome, uint256 _numberOfShares) public view returns (uint256) {
    uint256 _payoutNumerator = _market.getPayoutNumerator(_outcome);
    return _numberOfShares.mul(_payoutNumerator);
  }

  function calculateCreatorFee(IMarket _market, uint256 _amount) public view returns (uint256) {
    return _market.deriveMarketCreatorFeeAmount(_amount);
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

