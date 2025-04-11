// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol"; // Đảm bảo đường dẫn đúng đến file YourToken.sol

contract Vendor is Ownable {
    /// Tham chiếu đến hợp đồng ERC20 YourToken
    YourToken public yourToken;

    /// Tỉ lệ chuyển đổi: 1 ETH mua được 100 token (có thể điều chỉnh theo ý muốn)
    uint256 public constant tokensPerEth = 100;

    // Sự kiện cho chức năng mua và bán token
    event BuyTokens(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address indexed seller, uint256 amountOfETH, uint256 amountOfTokens);

    /// Constructor nhận địa chỉ của YourToken đã deploy
    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    /// Cho phép người dùng mua token. Người dùng gửi ETH và nhận token tương ứng.
    function buyTokens() public payable {
        uint256 amountOfEth = msg.value;
        require(amountOfEth > 0, "Send some ETH to buy tokens");

        // Tính số token cần chuyển dựa trên số ETH gửi
        uint256 amountOfTokens = amountOfEth * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountOfTokens, "Vendor does not have enough tokens");

        // Chuyển token từ hợp đồng vendor đến người mua
        address buyer = msg.sender;
        bool sent = yourToken.transfer(buyer, amountOfTokens);
        require(sent, "Failed to transfer token");

        emit BuyTokens(buyer, amountOfEth, amountOfTokens);
    }

    /// Cho phép chủ sở hữu (owner) rút toàn bộ ETH có trong hợp đồng.
    function withdraw() public onlyOwner {
        uint256 vendorBalance = address(this).balance;
        require(vendorBalance > 0, "Vendor does not have any ETH to withdraw");

        address ownerAddress = msg.sender;
        // Chuyển toàn bộ số ETH trong hợp đồng cho owner
        (bool sent, ) = ownerAddress.call{value: vendorBalance}("");
        require(sent, "Failed to withdraw");
    }

    /// Cho phép người dùng bán token cho vendor và nhận lại ETH
    /// Lưu ý: Người dùng cần phải approve vendor để hợp đồng có thể lấy token từ ví của họ.
    function sellTokens(uint256 amount) public {
        require(amount > 0, "Must sell a token amount greater than 0");

        address seller = msg.sender;
        uint256 userBalance = yourToken.balanceOf(seller);
        require(userBalance >= amount, "User does not have enough tokens");

        // Tính số ETH để trả lại dựa trên số token bán
        uint256 amountOfEth = amount / tokensPerEth;
        uint256 vendorEthBalance = address(this).balance;
        require(vendorEthBalance >= amountOfEth, "Vendor does not have enough ETH");

        // Chuyển token từ người dùng sang vendor
        bool sent = yourToken.transferFrom(seller, address(this), amount);
        require(sent, "Failed to transfer tokens");

        // Chuyển ETH từ vendor sang người bán
        (bool ethSent, ) = seller.call{value: amountOfEth}("");
        require(ethSent, "Failed to send back ETH");

        emit SellTokens(seller, amountOfEth, amount);
    }
}
