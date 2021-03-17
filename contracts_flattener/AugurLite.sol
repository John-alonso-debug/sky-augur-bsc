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

contract AugurLite is Controlled, IAugurLite {

  enum TokenType {
    ShareToken
  }

  event MarketCreated(bytes32 indexed topic, string description, string extraInfo, address indexed universe,
    address market, address indexed marketCreator, bytes32[] outcomes,
    uint256 marketCreationFee, int256 minPrice, int256 maxPrice, IMarket.MarketType marketType);

  event ShareTokenCreated(IShareToken[]  _shareTokens, address _market);
  event MarketResolved(address indexed universe, address indexed market);
  event UniverseCreated(address indexed universe, ERC20 denominationToken);
  event CompleteSetsPurchased(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
  event CompleteSetsSold(address indexed universe, address indexed market, address indexed account, uint256 numCompleteSets);
  event TradingProceedsClaimed(address indexed universe, address indexed shareToken, address indexed sender, address market,
    uint256 numShares, uint256 numPayoutTokens, uint256 finalTokenBalance);
  event TokensTransferred(address indexed universe, address indexed token, address indexed from, address to, uint256 value, TokenType tokenType, address market);
  event TokensMinted(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
  event TokensBurned(address indexed universe, address indexed token, address indexed target, uint256 amount, TokenType tokenType, address market);
  event MarketTransferred(address indexed universe, address indexed market, address from, address to);
  event MarketMailboxTransferred(address indexed universe, address indexed market, address indexed mailbox, address from, address to);
  event EscapeHatchChanged(bool isOn);
  event TimestampSet(uint256 newTimestamp);

  mapping(address => bool) private universes;

  //
  // Universe
  //

  function createUniverse(ERC20 _denominationToken) public returns (IUniverse) {
    UniverseFactory _universeFactory = UniverseFactory(controller.lookup("UniverseFactory"));
    IUniverse _newUniverse = _universeFactory.createUniverse(controller, _denominationToken);
    //TODO:Fix
    universes[address(_newUniverse)] = true;
    emit UniverseCreated(address(_newUniverse), _denominationToken);
    return _newUniverse;
  }

  function isKnownUniverse(IUniverse _universe) public view returns (bool) {
    return universes[address(_universe)];
  }

  //
  // Transfer
  //

  function trustedTransfer(ERC20 _token, address _from, address _to, uint256 _amount) public onlyWhitelistedCallers returns (bool) {
    require(_amount > 0, "Transfer amount needs to be greater than 0");
    require(_token.transferFrom(_from, _to, _amount), "Transfer failed");
    return true;
  }

  //
  // Logging
  //
   function logShareTokensCreated(IShareToken[] memory _shareTokens, address _market) public returns(bool){
     emit ShareTokenCreated(_shareTokens,_market);
     return true;

   }
  // This signature is intended for the categorical market creation. We use two signatures for the same event because of stack depth issues which can be circumvented by maintaining order of paramaters
  function logMarketCreated(bytes32 _topic, string memory _description, string memory _extraInfo, IUniverse _universe, address _market, address _marketCreator, bytes32[] memory _outcomes, int256 _minPrice, int256 _maxPrice, IMarket.MarketType _marketType) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe == IUniverse(msg.sender), "Sender is not the universe contract");
    //TODO:
    emit MarketCreated(_topic, _description, _extraInfo, address(_universe), _market, _marketCreator, _outcomes, 0, _minPrice, _maxPrice, _marketType);
    return true;
  }

  // This signature is intended for yesNo and scalar market creation. See function comment above for explanation.
  function logMarketCreated(bytes32 _topic, string memory _description, string memory _extraInfo,
    IUniverse _universe, address _market, address _marketCreator, int256 _minPrice, int256 _maxPrice,
    IMarket.MarketType _marketType) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe == IUniverse(msg.sender), "Sender is not the universe contract");
    emit MarketCreated(_topic, _description, _extraInfo, address(_universe), _market, _marketCreator, new bytes32[](0), 0, _minPrice, _maxPrice, _marketType);
    return true;
  }

  function logMarketResolved(IUniverse _universe) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IMarket _market = IMarket(msg.sender);
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    emit MarketResolved(address(_universe), address(_market));
    return true;
  }

  function logCompleteSetsPurchased(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    emit CompleteSetsPurchased(address(_universe), address(_market), _account, _numCompleteSets);
    return true;
  }

  function logCompleteSetsSold(IUniverse _universe, IMarket _market, address _account, uint256 _numCompleteSets) public onlyWhitelistedCallers returns (bool) {
    emit CompleteSetsSold(address(_universe), address(_market), _account, _numCompleteSets);
    return true;
  }

  function logTradingProceedsClaimed(IUniverse _universe, address _shareToken, address _sender, address _market, uint256 _numShares, uint256 _numPayoutTokens, uint256 _finalTokenBalance) public onlyWhitelistedCallers returns (bool) {
    emit TradingProceedsClaimed(address(_universe), _shareToken, _sender, _market, _numShares, _numPayoutTokens, _finalTokenBalance);
    return true;
  }

  function logShareTokensTransferred(IUniverse _universe, address _from, address _to, uint256 _value) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensTransferred(address(_universe), msg.sender, _from, _to, _value, TokenType.ShareToken, address(_shareToken.getMarket()));
    return true;
  }

  function logShareTokenBurned(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensBurned(address(_universe), msg.sender, _target, _amount, TokenType.ShareToken, address(_shareToken.getMarket()));
    return true;
  }

  function logShareTokenMinted(IUniverse _universe, address _target, uint256 _amount) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IShareToken _shareToken = IShareToken(msg.sender);
    require(_universe.isContainerForShareToken(_shareToken), "ShareToken does not belong to the universe");
    emit TokensMinted(address(_universe), msg.sender, _target, _amount, TokenType.ShareToken, address(_shareToken.getMarket()));
    return true;
  }

  function logTimestampSet(uint256 _newTimestamp) public returns (bool) {
    require(msg.sender == controller.lookup("Time"), "Sender is not the Time contract");
    emit TimestampSet(_newTimestamp);
    return true;
  }

  function logMarketTransferred(IUniverse _universe, address _from, address _to) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    IMarket _market = IMarket(msg.sender);
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    emit MarketTransferred(address(_universe), address(_market), _from, _to);
    return true;
  }

  function logMarketMailboxTransferred(IUniverse _universe, IMarket _market, address _from, address _to) public returns (bool) {
    require(isKnownUniverse(_universe), "The universe is not known");
    require(_universe.isContainerForMarket(_market), "Market does not belong to the universe");
    require(IMailbox(msg.sender) == _market.getMarketCreatorMailbox(), "Sender is not the market creator mailbox");
    emit MarketMailboxTransferred(address(_universe), address(_market), msg.sender, _from, _to);
    return true;
  }

  function logEscapeHatchChanged(bool _isOn) public returns (bool) {
    require(msg.sender == address(controller), "Sender is not the controller");
    emit EscapeHatchChanged(_isOn);
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

contract UniverseFactory {
  function createUniverse(IController _controller, ERC20 _denominationToken) public returns (IUniverse) {

    //TODO: Fix Error: Explicit type conversion not allowed from "contract Delegator" to "contract IUniverse".
    Delegator _delegator = new Delegator(_controller, "Universe");
    IUniverse _universe = IUniverse(address(_delegator));
    _universe.initialize(_denominationToken);
    return _universe;
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

