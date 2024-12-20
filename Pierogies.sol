// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Minimal interface for BEP-20 (compatible with ERC-20)
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// BEP-20 token implementation with security enhancements
contract BEP20Token is IBEP20, ReentrancyGuard {
    string public name = "Pierogies";      // Name of the token
    string public symbol = "PIRGS";        // Symbol of the token
    uint8 public decimals = 18;            // Number of decimal places
    uint256 public totalSupply;            // Total token supply

    // Mapping of address to token balance
    mapping(address => uint256) public _balances;
    // Mapping of address to mapping of spender to amount
    mapping(address => mapping(address => uint256)) public _allowances;

    // Contract owner address
    address public owner;

    constructor() {
        owner = msg.sender;
        totalSupply = 1_000_000_000_000 * 10 ** decimals; // 1 trillion tokens
        _balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    // Internal function to handle token transfers
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] >= amount, "Transfer amount exceeds balance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    // Internal function to handle token approvals
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    // Function to burn tokens with reentrancy protection
    // Follows checks-effects-interactions pattern
    function burn(uint256 amount) external nonReentrant {
        uint256 burnAmount = amount * 10 ** decimals;
        require(_balances[msg.sender] >= burnAmount, "Burn amount exceeds balance");
        
        // First update the user's balance
        _balances[msg.sender] -= burnAmount;
        
        // Then decrease the total supply
        totalSupply -= burnAmount;
        
        emit Transfer(msg.sender, address(0), burnAmount);
    }
}
