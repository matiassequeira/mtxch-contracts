pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract TestWETH is ERC20, Ownable {
    constructor(uint256 _initialSupply) ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, _initialSupply);
    }

    function mintTo(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

}