// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/** Errors */
error ERC20__YouAreNotRichEnough(uint256 amount);
error ERC20__AllowanceExceeded(uint256 amount);
error ERC20__AmountTooSmall(uint256 amount);
error ERC20__AmountTooBig(uint256 amount);
error ERC20__AddressZero();
error ERC20__SelfTransfer();
error ERC20__SelfApprove();

/**
 * @dev This is a fee on transfer token,
 * which means if person A sends C amount to person B then person B will receive (C - fee),
 * fee will go to the token deployer
 * @dev fee = 0.1% = 1/1000
 */
contract ERC20 is IERC20 {
    /** Variables */
    address private immutable i_owner;
    uint256 private constant TOTAL_SUPPLY = 1e8;
    uint256 private constant DECIMALS = 1e18;

    /**
     * @dev map address to their balance
     */
    mapping(address => uint256) private s_balance;
    /**
     * @dev map allower to spender to  amount allowed
     * @dev for example: A[B[100]] means that person A allows person B to spend 100 Eth that belongs to A
     */
    mapping(address => mapping(address => uint256)) private s_allowance;

    /** Modifers */
    modifier isValidTransfer(
        address from,
        address to,
        uint256 amount
    ) {
        if (from == address(0) || to == address(0)) revert ERC20__AddressZero();
        if (from == to) revert ERC20__SelfTransfer();
        if (amount <= 0) revert ERC20__AmountTooSmall(amount);
        if (amount > TOTAL_SUPPLY) revert ERC20__AmountTooBig(amount);
        if (amount > s_balance[from]) revert ERC20__YouAreNotRichEnough(amount);
        _;
    }

    modifier isValidApproval(address spender, uint256 amount) {
        if (msg.sender == address(0) || spender == address(0))
            revert ERC20__AddressZero();
        if (spender == msg.sender) revert ERC20__SelfApprove();
        if (amount <= 0) revert ERC20__AmountTooSmall(amount);
        if (amount > TOTAL_SUPPLY) revert ERC20__AmountTooBig(amount);
        if (amount > s_balance[msg.sender])
            revert ERC20__YouAreNotRichEnough(amount);
        _;
    }

    /**
     * @dev Constructor
     */
    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @dev This section is for implementing IERC20 interface
     * @dev Functions are grouped and placed in order according to their state mutability: view, pure, normal
     */
    function totalSupply() external pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view returns (uint256) {
        return s_balance[account];
    }

    function allowance(
        address allower,
        address spender
    ) external view override returns (uint256) {
        return s_allowance[allower][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override isValidApproval(spender, amount) returns (bool) {
        if (spender == msg.sender) revert ERC20__SelfApprove();
        s_allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override isValidTransfer(from, to, amount) returns (bool) {
        // Auto detece allowance-based transfer
        if (from != msg.sender) {
            if (amount > s_allowance[from][to]) revert ERC20__AllowanceExceeded(amount);
            s_allowance[from][to] -= amount;

        }
        uint256 fee = calcFee(amount);
        s_balance[from] -= amount;
        s_balance[to] += (amount - fee);
        return true;
    }

    /**
     * @dev This section is reserved for private/internal functions
     */
    function calcFee(uint256 amount) internal pure returns (uint256) {
        unchecked {
            uint256 fee = (amount * DECIMALS) / 1e21;
            return fee;
        }
    }
}
