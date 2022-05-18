//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public spartanTokenAddress;

    constructor(address _SpartanToken) ERC20("Spartan Token", "SP") {
        require(
            _SpartanToken != address(0),
            "Token address passed is a null address"
        );
        spartanTokenAddress = _SpartanToken;
    }

    function getReserve() public view returns (uint256) {
        return ERC20(spartanTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 spartanTokenReserve = getReserve();
        ERC20 spartanToken = ERC20(spartanTokenAddress);

        if (spartanTokenReserve == 0) {
            spartanToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethBalance - msg.value;
            uint256 spartanTokenAmount = (msg.value * spartanTokenReserve) /
                (ethReserve);
            require(
                _amount >= spartanTokenAmount,
                "Amount of tokens sent is less than the minimum tokens required"
            );
            spartanToken.transferFrom(
                msg.sender,
                address(this),
                spartanTokenAmount
            );
            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    function removeLiquidity(uint256 _amount)
        public
        returns (uint256, uint256)
    {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();

        uint256 ethAmount = (ethReserve * _amount) / _totalSupply;
        uint256 spartanTokenAmount = (getReserve() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        ERC20(spartanTokenAddress).transfer(msg.sender, spartanTokenAmount);
        return (ethAmount, spartanTokenAmount);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    function ethToSpartanToken(uint256 _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        ERC20(spartanTokenAddress).transfer(msg.sender, tokensBought);
    }

    function spartanTokenToEth(uint256 _tokensSold, uint256 _minEth) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");
        ERC20(spartanTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(ethBought);
    }
}
