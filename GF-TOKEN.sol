// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyGoodFortune {
    string public name = "GoodFortune";
    string public symbol = "GF";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 5_000_000 * 1e18;
    uint256 public constant WEEKLY_MINT_AMOUNT = 100_000 * 1e18;
    uint256 public lastMintTime;

    /** 
     * @dev HARDCODED ADDRESSES
     * Using 'constant' saves the most gas and fixes the addresses at compile-time.
     * Replace the addresses below with your actual BSC wallets.
     */
    address public constant OWNER = 0x83cFE8370E673E08886e9E2283c58522E9f27189; 
    address public constant DISTRIBUTION_WALLET = 0xD3dd756CEf00F49B62757283684e9e891BE310B1;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == OWNER, "Not owner");
        _;
    }

    constructor() {
        // No arguments needed anymore since addresses are hardcoded
        uint256 initialSupply = 3_000_000 * 1e18;
        totalSupply = initialSupply;
        
        // Initial supply goes to the fixed distribution wallet
        balanceOf[DISTRIBUTION_WALLET] = initialSupply;
        lastMintTime = block.timestamp;

        emit Transfer(address(0), DISTRIBUTION_WALLET, initialSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        unchecked {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
        }
        emit Transfer(msg.sender, _to, _value);
        return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        unchecked {
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            allowance[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mintWeekly() public onlyOwner returns (bool) {
        require(block.timestamp >= lastMintTime + 7 days, "Mint not available yet");
        require(totalSupply + WEEKLY_MINT_AMOUNT <= MAX_SUPPLY, "Max supply reached");

        totalSupply += WEEKLY_MINT_AMOUNT;
        balanceOf[DISTRIBUTION_WALLET] += WEEKLY_MINT_AMOUNT;
        lastMintTime = block.timestamp;

        emit Mint(DISTRIBUTION_WALLET, WEEKLY_MINT_AMOUNT);
        emit Transfer(address(0), DISTRIBUTION_WALLET, WEEKLY_MINT_AMOUNT);
        return true;
    }

    /**
     * @dev Renamed for Binance Smart Chain (BNB).
     * Withdraws any BNB (native token) sent to this contract back to the owner.
     */
    function withdrawBNB(uint256 _amount) public onlyOwner {
        require(address(this).balance >= _amount, "Not enough balance");
        (bool success, ) = payable(OWNER).call{value: _amount}("");
        require(success, "BNB Transfer failed");
    }

    // BSC contracts should use receive() to handle incoming BNB
    receive() external payable {}
    fallback() external payable {}
}