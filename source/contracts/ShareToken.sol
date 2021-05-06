pragma solidity ^0.5.16;

import 'IMarket.sol';
import 'IShareToken.sol';
import 'libraries/DelegationTarget.sol';
//import 'libraries/token/VariableSupplyToken.sol';
import 'libraries/ITyped.sol';
import 'libraries/Initializable.sol';
import 'libraries/token/BEP20.sol';


contract ShareToken is DelegationTarget, ITyped, Initializable, IShareToken, BEP20{

  string  public _name ;
  uint8  public _decimals ;
  string  public _symbol ;

  IMarket private market;
  uint256 private outcome;

  constructor() BEP20("ShareToken","SHARE") public {

  }

  function initialize(IMarket _market, uint256 _outcome) external beforeInitialized returns(bool) {
    endInitialization();
    market = _market;
    outcome = _outcome;


    return true;
  }

  function createShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    _mint(_owner, _fxpValue);
    return true;
  }

  function destroyShares(address _owner, uint256 _fxpValue) external onlyWhitelistedCallers returns(bool) {
    _burn(_owner, _fxpValue);
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
