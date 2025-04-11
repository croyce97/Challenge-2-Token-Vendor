// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YourToken is ERC20 {
    constructor() ERC20("Gold", "GLD") {
        // Mint 1000 tokens, mỗi token có 18 chữ số thập phân (theo chuẩn của ERC20)
        _mint(msg.sender, 1000 * 10 ** decimals());
    }
}
