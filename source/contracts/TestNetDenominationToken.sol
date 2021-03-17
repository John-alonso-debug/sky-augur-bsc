pragma solidity 0.5.16;

import 'Controlled.sol';
import 'libraries/ITyped.sol';
import 'libraries/token/VariableSupplyToken.sol';
import 'libraries/DelegationTarget.sol';

library address_make_payable {
  function make_payable(address x) internal pure returns (address payable) {
    return address(uint160(x));
  }
}

contract TestNetDenominationToken is DelegationTarget, ITyped, VariableSupplyToken {

  string constant public name = "TestNetDenominationToken";
  string constant public symbol = "USDT";
  uint8 constant public decimals = 6;

  function depositEther() public payable returns (bool) {
    mint(msg.sender, msg.value);
    assert(address(this).balance >= totalSupply());
    return true;
  }

  function withdrawEther(uint256 _amount) public returns (bool) {
    withdrawEtherInternal(msg.sender, msg.sender, _amount);
    return true;
  }
  //TODO:
  using address_make_payable for address;
  function withdrawEtherInternal(address _from, address _to, uint256 _amount) public payable returns (bool) {
    require(_amount > 0 && _amount <= balances[_from], "Invalid amount to withdraw");
    burn(_from, _amount);
    address payable addr = _to.make_payable();
    address(addr).transfer(_amount);
    //assert(address(this).balance >= totalSupply());
    //assert(address(this).balance >= totalSupply());
    return true;
  }

  function faucet(uint256 _amount) public returns (bool) {
    mint(msg.sender, _amount);
    return true;
  }

  function getTypeName() public view returns (bytes32) {
    return "TestNetDenominationToken";
  }

  function onMint(address, uint256) internal returns (bool) {
    return true;
  }

  function onBurn(address, uint256) internal returns (bool) {
    return true;
  }

  function onTokenTransfer(address, address, uint256) internal returns (bool) {
    return true;
  }
}

