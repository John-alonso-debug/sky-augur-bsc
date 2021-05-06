pragma solidity 0.4.26;

import 'IMarket.sol';
import 'IUniverse.sol';
import 'IShareToken.sol';
import 'libraries/token/BEP20.sol';


contract MaliciousMarket {
  IMarket private victimMarket;
  uint256 public getNumTicks = 1;

  function MaliciousMarket(IMarket _market) public {
    victimMarket = _market;
  }

  function getShareToken(uint256 _outcome)  public view returns (IShareToken) {
    return victimMarket.getShareToken(_outcome);
  }

  function getNumberOfOutcomes() public view returns (uint256) {
    return victimMarket.getNumberOfOutcomes();
  }

  function getDenominationToken() public view returns (BEP20) {
    return victimMarket.getDenominationToken();
  }

  function getUniverse() public view returns (IUniverse) {
    return victimMarket.getUniverse();
  }
}
