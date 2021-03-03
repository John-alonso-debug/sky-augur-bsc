pragma solidity 0.5.16;

import 'Controlled.sol';


contract DelegationTarget is Controlled {
  bytes32 public controllerLookupName;
}
