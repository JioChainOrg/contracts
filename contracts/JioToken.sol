// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract JioToken  is ERC20("JIOCHAIN","JIO") {
    uint256 public MAX_SUPPLY = 1000000000*1e18;
    constructor()  {
      _mint(msg.sender,MAX_SUPPLY);
    }

   
}
