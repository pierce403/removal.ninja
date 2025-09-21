// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.4.16 >=0.6.2 >=0.8.4 ^0.8.19 ^0.8.20;

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.1.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If EIP-1153 (transient storage) is available on the chain you're deploying at,
 * consider using {ReentrancyGuardTransient} instead.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.4.0) (interfaces/draft-IERC6093.sol)

/**
 * @dev Standard ERC-20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC-721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in ERC-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC-1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC-1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC-20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// lib/openzeppelin-contracts/contracts/utils/Pausable.sol

// OpenZeppelin Contracts (last updated v5.3.0) (utils/Pausable.sol)

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC-20
 * applications.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * Both values are immutable: they can only be set once during construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Skips emitting an {Approval} event indicating an allowance update. This is not
     * required by the ERC. See {xref-ERC20-_approve-address-address-uint256-bool-}[_approve].
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner`'s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     *
     * ```solidity
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner`'s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// src/RemovalNinja.sol

/**
 * @title RemovalNinja
 * @dev Decentralized data broker removal protocol with token incentives
 * @author Pierce
 */
contract RemovalNinja is ERC20, Ownable, ReentrancyGuard, Pausable {
    // ============ Constants ============
    
    uint256 public constant BROKER_SUBMISSION_REWARD = 100 * 10**18; // 100 RN tokens
    uint256 public constant REMOVAL_PROCESSING_REWARD = 50 * 10**18; // 50 RN tokens
    uint256 public constant MIN_USER_STAKE = 10 * 10**18; // 10 RN tokens
    uint256 public constant MIN_PROCESSOR_STAKE = 1000 * 10**18; // 1,000 RN tokens
    uint256 public constant SLASH_PERCENTAGE = 10; // 10% slashing for poor performance
    uint256 public constant MAX_SELECTED_PROCESSORS = 5; // Max processors a user can select
    
    // ============ Structs ============
    
    struct DataBroker {
        uint256 id;
        string name;
        string website;
        string removalInstructions;
        address submitter;
        bool isVerified;
        uint256 submissionTime;
        uint256 totalRemovals;
    }
    
    struct Processor {
        address addr;
        bool isProcessor;
        uint256 stake;
        string description;
        uint256 completedRemovals;
        uint256 reputation; // Score out of 100
        uint256 registrationTime;
        bool isSlashed;
    }
    
    struct User {
        bool isStakingForRemoval;
        uint256 stakeAmount;
        uint256 stakeTime;
        address[] selectedProcessors;
    }
    
    struct RemovalRequest {
        uint256 id;
        address user;
        uint256 brokerId;
        address processor;
        bool isCompleted;
        bool isVerified;
        uint256 requestTime;
        uint256 completionTime;
        string zkProof; // Future: zkEmail proof hash
    }
    
    // ============ State Variables ============
    
    mapping(uint256 => DataBroker) public dataBrokers;
    mapping(address => Processor) public processors;
    mapping(address => User) public users;
    mapping(uint256 => RemovalRequest) public removalRequests;
    mapping(address => uint256) public userStakeAmount;
    mapping(address => address[]) public userSelectedProcessors;
    
    uint256 public nextBrokerId = 1;
    uint256 public nextRemovalId = 1;
    address[] public allProcessors;
    uint256[] public allBrokerIds;
    
    // ============ Events ============
    
    event DataBrokerSubmitted(
        uint256 indexed brokerId,
        string name,
        address indexed submitter
    );
    
    event ProcessorRegistered(
        address indexed processor,
        uint256 stake,
        string description
    );
    
    event UserStakedForRemoval(
        address indexed user,
        uint256 amount,
        address[] selectedProcessors
    );
    
    event RemovalRequested(
        uint256 indexed removalId,
        address indexed user,
        uint256 indexed brokerId,
        address processor
    );
    
    event RemovalCompleted(
        uint256 indexed removalId,
        address indexed processor,
        string zkProof
    );
    
    event ProcessorSlashed(
        address indexed processor,
        uint256 slashedAmount,
        string reason
    );
    
    event BrokerVerified(
        uint256 indexed brokerId,
        address indexed verifier
    );
    
    // ============ Modifiers ============
    
    modifier onlyProcessor() {
        require(processors[msg.sender].isProcessor, "Not a registered processor");
        require(!processors[msg.sender].isSlashed, "Processor is slashed");
        _;
    }
    
    modifier onlyActiveUser() {
        require(users[msg.sender].isStakingForRemoval, "User not staking for removal");
        _;
    }
    
    modifier validBrokerId(uint256 brokerId) {
        require(brokerId > 0 && brokerId < nextBrokerId, "Invalid broker ID");
        _;
    }
    
    modifier validRemovalId(uint256 removalId) {
        require(removalId > 0 && removalId < nextRemovalId, "Invalid removal ID");
        _;
    }
    
    // ============ Constructor ============
    
    constructor() ERC20("RemovalNinja", "RN") Ownable(msg.sender) {
        // Mint initial supply to owner for distribution
        _mint(msg.sender, 1000000 * 10**18); // 1M RN tokens
    }
    
    // ============ Data Broker Functions ============
    
    /**
     * @dev Submit a new data broker to the registry
     * @param name The name of the data broker
     * @param website The website URL of the data broker
     * @param removalInstructions Instructions for data removal
     */
    function submitDataBroker(
        string calldata name,
        string calldata website,
        string calldata removalInstructions
    ) external whenNotPaused {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(website).length > 0, "Website cannot be empty");
        
        uint256 brokerId = nextBrokerId++;
        
        dataBrokers[brokerId] = DataBroker({
            id: brokerId,
            name: name,
            website: website,
            removalInstructions: removalInstructions,
            submitter: msg.sender,
            isVerified: false,
            submissionTime: block.timestamp,
            totalRemovals: 0
        });
        
        allBrokerIds.push(brokerId);
        
        // Reward the submitter
        _mint(msg.sender, BROKER_SUBMISSION_REWARD);
        
        emit DataBrokerSubmitted(brokerId, name, msg.sender);
    }
    
    /**
     * @dev Verify a data broker (owner only)
     * @param brokerId The ID of the broker to verify
     */
    function verifyDataBroker(uint256 brokerId) external onlyOwner validBrokerId(brokerId) {
        dataBrokers[brokerId].isVerified = true;
        emit BrokerVerified(brokerId, msg.sender);
    }
    
    /**
     * @dev Get all data brokers
     */
    function getAllDataBrokers() external view returns (DataBroker[] memory) {
        DataBroker[] memory brokers = new DataBroker[](allBrokerIds.length);
        for (uint256 i = 0; i < allBrokerIds.length; i++) {
            brokers[i] = dataBrokers[allBrokerIds[i]];
        }
        return brokers;
    }
    
    // ============ Processor Functions ============
    
    /**
     * @dev Register as a removal processor
     * @param stakeAmount Amount of RN tokens to stake
     * @param description Description of processor services
     */
    function registerProcessor(
        uint256 stakeAmount,
        string calldata description
    ) external whenNotPaused {
        require(!processors[msg.sender].isProcessor, "Already registered as processor");
        require(stakeAmount >= MIN_PROCESSOR_STAKE, "Insufficient stake amount");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient balance");
        
        // Transfer stake to contract
        _transfer(msg.sender, address(this), stakeAmount);
        
        processors[msg.sender] = Processor({
            addr: msg.sender,
            isProcessor: true,
            stake: stakeAmount,
            description: description,
            completedRemovals: 0,
            reputation: 100, // Start with perfect reputation
            registrationTime: block.timestamp,
            isSlashed: false
        });
        
        allProcessors.push(msg.sender);
        
        emit ProcessorRegistered(msg.sender, stakeAmount, description);
    }
    
    /**
     * @dev Get all registered processors
     */
    function getAllProcessors() external view returns (Processor[] memory) {
        Processor[] memory processorList = new Processor[](allProcessors.length);
        for (uint256 i = 0; i < allProcessors.length; i++) {
            processorList[i] = processors[allProcessors[i]];
        }
        return processorList;
    }
    
    /**
     * @dev Slash a processor for poor performance (owner only)
     * @param processorAddr Address of the processor to slash
     * @param reason Reason for slashing
     */
    function slashProcessor(
        address processorAddr,
        string calldata reason
    ) external onlyOwner {
        require(processors[processorAddr].isProcessor, "Not a processor");
        require(!processors[processorAddr].isSlashed, "Already slashed");
        
        uint256 slashAmount = (processors[processorAddr].stake * SLASH_PERCENTAGE) / 100;
        processors[processorAddr].stake -= slashAmount;
        processors[processorAddr].isSlashed = true;
        processors[processorAddr].reputation = 0;
        
        // Burn the slashed tokens
        _burn(address(this), slashAmount);
        
        emit ProcessorSlashed(processorAddr, slashAmount, reason);
    }
    
    // ============ User Functions ============
    
    /**
     * @dev Stake tokens for removal services and select processors
     * @param stakeAmount Amount of RN tokens to stake
     * @param selectedProcessors Array of processor addresses to trust
     */
    function stakeForRemoval(
        uint256 stakeAmount,
        address[] calldata selectedProcessors
    ) external whenNotPaused {
        require(!users[msg.sender].isStakingForRemoval, "Already staking for removal");
        require(stakeAmount >= MIN_USER_STAKE, "Insufficient stake amount");
        require(selectedProcessors.length > 0, "Must select at least one processor");
        require(selectedProcessors.length <= MAX_SELECTED_PROCESSORS, "Too many processors selected");
        require(balanceOf(msg.sender) >= stakeAmount, "Insufficient balance");
        
        // Validate all selected processors
        for (uint256 i = 0; i < selectedProcessors.length; i++) {
            require(processors[selectedProcessors[i]].isProcessor, "Invalid processor");
            require(!processors[selectedProcessors[i]].isSlashed, "Processor is slashed");
        }
        
        // Transfer stake to contract
        _transfer(msg.sender, address(this), stakeAmount);
        
        users[msg.sender] = User({
            isStakingForRemoval: true,
            stakeAmount: stakeAmount,
            stakeTime: block.timestamp,
            selectedProcessors: selectedProcessors
        });
        
        userStakeAmount[msg.sender] = stakeAmount;
        userSelectedProcessors[msg.sender] = selectedProcessors;
        
        emit UserStakedForRemoval(msg.sender, stakeAmount, selectedProcessors);
    }
    
    /**
     * @dev Request removal from a specific data broker
     * @param brokerId The ID of the broker to request removal from
     */
    function requestRemoval(uint256 brokerId) external onlyActiveUser validBrokerId(brokerId) {
        address[] memory selectedProcessors = users[msg.sender].selectedProcessors;
        require(selectedProcessors.length > 0, "No processors selected");
        
        // Simple processor selection (first available)
        // In production, this could be more sophisticated
        address selectedProcessor = selectedProcessors[0];
        require(processors[selectedProcessor].isProcessor, "Selected processor not available");
        require(!processors[selectedProcessor].isSlashed, "Selected processor is slashed");
        
        uint256 removalId = nextRemovalId++;
        
        removalRequests[removalId] = RemovalRequest({
            id: removalId,
            user: msg.sender,
            brokerId: brokerId,
            processor: selectedProcessor,
            isCompleted: false,
            isVerified: false,
            requestTime: block.timestamp,
            completionTime: 0,
            zkProof: ""
        });
        
        emit RemovalRequested(removalId, msg.sender, brokerId, selectedProcessor);
    }
    
    /**
     * @dev Complete a removal request (processor only)
     * @param removalId The ID of the removal request
     * @param zkProof The zkEmail proof hash (future implementation)
     */
    function completeRemoval(
        uint256 removalId,
        string calldata zkProof
    ) external onlyProcessor validRemovalId(removalId) {
        RemovalRequest storage request = removalRequests[removalId];
        require(request.processor == msg.sender, "Not assigned processor");
        require(!request.isCompleted, "Already completed");
        
        request.isCompleted = true;
        request.completionTime = block.timestamp;
        request.zkProof = zkProof;
        
        // Update processor stats
        processors[msg.sender].completedRemovals++;
        
        // Update broker stats
        dataBrokers[request.brokerId].totalRemovals++;
        
        // Reward the processor
        _mint(msg.sender, REMOVAL_PROCESSING_REWARD);
        
        emit RemovalCompleted(removalId, msg.sender, zkProof);
    }
    
    /**
     * @dev Get user's selected processors
     * @param user Address of the user
     */
    function getUserSelectedProcessors(address user) external view returns (address[] memory) {
        return userSelectedProcessors[user];
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Pause the contract (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Emergency withdrawal function (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = balanceOf(address(this));
        if (balance > 0) {
            _transfer(address(this), owner(), balance);
        }
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get contract statistics
     */
    function getStats() external view returns (
        uint256 totalBrokers,
        uint256 totalProcessors,
        uint256 totalRemovals,
        uint256 contractBalance
    ) {
        totalBrokers = allBrokerIds.length;
        totalProcessors = allProcessors.length;
        totalRemovals = nextRemovalId - 1;
        contractBalance = balanceOf(address(this));
    }
    
    /**
     * @dev Check if an address is a registered processor
     * @param addr Address to check
     */
    function isProcessor(address addr) external view returns (bool) {
        return processors[addr].isProcessor && !processors[addr].isSlashed;
    }
    
    /**
     * @dev Get processor reputation
     * @param processorAddr Address of the processor
     */
    function getProcessorReputation(address processorAddr) external view returns (uint256) {
        require(processors[processorAddr].isProcessor, "Not a processor");
        return processors[processorAddr].reputation;
    }
}

