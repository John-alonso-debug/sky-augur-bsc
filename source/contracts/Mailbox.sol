pragma solidity 0.5.16;

import 'IMailbox.sol';
import 'IMarket.sol';
import 'libraries/DelegationTarget.sol';
import 'libraries/Ownable.sol';
import 'libraries/token/IBEP20.sol';
import 'libraries/Initializable.sol';
//import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract Mailbox is DelegationTarget, Ownable, Initializable, IMailbox {
  IMarket private market;

  function initialize(address _owner, IMarket _market) public onlyInGoodTimes beforeInitialized returns (bool) {
    endInitialization();
    owner = _owner;
    market = _market;
    return true;
  }

  function withdrawTokens(IBEP20 _token) public onlyOwner returns (bool) {
    uint256 _balance = _token.balanceOf(address(this));
    require(_token.transfer(owner, _balance), "Token transfer failed");
    return true;
  }

  function onTransferOwnership(address _owner, address _newOwner) internal returns (bool) {
    controller.getAugurLite().logMarketMailboxTransferred(market.getUniverse(), market, _owner, _newOwner);
    return true;
  }
}
