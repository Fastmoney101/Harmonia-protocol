// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

/// @title HMO Token
/// @notice Native utility, governance, and work token for the Harmonia Protocol
/// @dev ERC-20-like implementation with fixed supply minted at deployment
contract HMO {
    string public constant name = "Harmonia Token";
    string public constant symbol = "HMO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _initialSupply) {
        require(_initialSupply > 0, "HMO: zero supply");
        totalSupply = _initialSupply;
        balanceOf[msg.sender] = _initialSupply;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "HMO: allowance exceeded");

        if (allowed != type(uint256).max) {
            unchecked {
                allowance[from][msg.sender] = allowed - value;
            }
        }

        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "HMO: transfer to zero address");
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "HMO: insufficient balance");

        unchecked {
            balanceOf[from] = fromBalance - value;
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);
    }
}
