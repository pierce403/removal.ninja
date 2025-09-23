// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uniswap V2 interfaces
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

/**
 * @title AddLiquidity
 * @dev Script to add RN token liquidity to Uniswap V2 on Base Sepolia
 */
contract AddLiquidity is Script {
    
    // Base Sepolia Uniswap V2 addresses (placeholder - not used since we deploy SimpleDEX)
    // Note: These may need to be updated with actual Base Sepolia addresses
    address constant UNISWAP_V2_ROUTER = 0x4648a43B2C14Da09FdF82B161150d3F634f40491; // Example address
    address constant UNISWAP_V2_FACTORY = 0xcAd0d7f1f6BA2c3e5Ab4a4dD96db04b5e3C8DCe5; // Example address
    
    // If Uniswap isn't deployed on Base Sepolia, we'll use a simple alternative
    bool constant USE_SIMPLE_DEX = true;
    
    // Our token contract addresses
    address constant REMOVAL_NINJA_TOKEN = 0xA7b02F76D863b9467eCd80Eab3b9fd6aCe18200A;
    
    function run() public {
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Adding RN Token Liquidity ===");
        console2.log("Deployer: %s", deployer);
        console2.log("Token: %s", REMOVAL_NINJA_TOKEN);
        console2.log("Deployer Balance: %s ETH", deployer.balance / 1e18);
        
        // Check token balance
        IERC20 token = IERC20(REMOVAL_NINJA_TOKEN);
        uint256 tokenBalance = token.balanceOf(deployer);
        console2.log("Token Balance: %s RN", tokenBalance / 1e18);
        
        if (tokenBalance == 0) {
            console2.log("ERROR: No tokens to add to liquidity!");
            return;
        }
        
        if (deployer.balance < 1 ether) {
            console2.log("ERROR: Need at least 1 ETH for liquidity!");
            return;
        }

        vm.startBroadcast(deployerPrivateKey);

        // Calculate amounts: 50% of tokens + 1 ETH
        uint256 tokenAmount = tokenBalance / 2; // 50% of tokens
        uint256 ethAmount = 1 ether; // 1 ETH
        
        console2.log("Adding liquidity:");
        console2.log("- Tokens: %s RN", tokenAmount / 1e18);
        console2.log("- ETH: %s", ethAmount / 1e18);

        if (USE_SIMPLE_DEX) {
            // Deploy a simple liquidity contract since Uniswap might not be on Base Sepolia
            console2.log("Deploying simple DEX for liquidity...");
            SimpleDEX dex = new SimpleDEX(REMOVAL_NINJA_TOKEN);
            
            // Approve tokens for the DEX
            token.approve(address(dex), tokenAmount);
            
            // Add liquidity to our simple DEX
            dex.addLiquidity{value: ethAmount}(tokenAmount);
            
            console2.log("Simple DEX deployed at: %s", address(dex));
            console2.log("Liquidity added successfully!");
            
            // Save DEX address for frontend integration
            _writeDEXInfo(address(dex), tokenAmount, ethAmount);
            
        } else {
            // Try to use Uniswap V2 (if available)
            console2.log("Attempting to use Uniswap V2...");
            
            // This section would require actual Uniswap addresses on Base Sepolia
            // For now, we'll fall back to the simple DEX
            revert("Uniswap V2 not configured for Base Sepolia - use Simple DEX");
        }

        vm.stopBroadcast();
        
        console2.log("=== Liquidity Addition Complete ===");
    }
    
    function _writeDEXInfo(address dexAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        string memory dexInfo = string(abi.encodePacked(
            '{\n',
            '  "network": "Base Sepolia",\n',
            '  "dex": "SimpleDEX",\n',
            '  "address": "', vm.toString(dexAddress), '",\n',
            '  "initialLiquidity": {\n',
            '    "tokens": "', vm.toString(tokenAmount / 1e18), '",\n',
            '    "eth": "', vm.toString(ethAmount / 1e18), '"\n',
            '  },\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}'
        ));
        
        vm.writeFile("dex-deployment.json", dexInfo);
    }
}

/**
 * @title SimpleDEX
 * @dev A simple decentralized exchange for RN tokens
 */
contract SimpleDEX {
    IERC20 public immutable token;
    
    uint256 public tokenReserves;
    uint256 public ethReserves;
    uint256 public totalLiquidity;
    
    mapping(address => uint256) public liquidityBalance;
    
    event LiquidityAdded(address indexed provider, uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);
    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event TokensSold(address indexed seller, uint256 tokenAmount, uint256 ethAmount);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function addLiquidity(uint256 tokenAmount) external payable {
        require(msg.value > 0, "Must send ETH");
        require(tokenAmount > 0, "Must send tokens");
        
        uint256 liquidity;
        
        if (totalLiquidity == 0) {
            // Initial liquidity
            liquidity = msg.value;
        } else {
            // Proportional liquidity
            liquidity = (msg.value * totalLiquidity) / ethReserves;
        }
        
        // Transfer tokens from user
        token.transferFrom(msg.sender, address(this), tokenAmount);
        
        // Update reserves
        tokenReserves += tokenAmount;
        ethReserves += msg.value;
        totalLiquidity += liquidity;
        liquidityBalance[msg.sender] += liquidity;
        
        emit LiquidityAdded(msg.sender, tokenAmount, msg.value, liquidity);
    }
    
    function buyTokens() external payable {
        require(msg.value > 0, "Must send ETH");
        require(tokenReserves > 0 && ethReserves > 0, "No liquidity");
        
        // Simple constant product formula: x * y = k
        uint256 tokenAmount = (msg.value * tokenReserves) / (ethReserves + msg.value);
        require(tokenAmount > 0, "Insufficient token output");
        
        // Update reserves
        ethReserves += msg.value;
        tokenReserves -= tokenAmount;
        
        // Transfer tokens to buyer
        token.transfer(msg.sender, tokenAmount);
        
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }
    
    function sellTokens(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Must send tokens");
        require(tokenReserves > 0 && ethReserves > 0, "No liquidity");
        
        // Calculate ETH output
        uint256 ethAmount = (tokenAmount * ethReserves) / (tokenReserves + tokenAmount);
        require(ethAmount > 0, "Insufficient ETH output");
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");
        
        // Transfer tokens from seller
        token.transferFrom(msg.sender, address(this), tokenAmount);
        
        // Update reserves
        tokenReserves += tokenAmount;
        ethReserves -= ethAmount;
        
        // Transfer ETH to seller
        payable(msg.sender).transfer(ethAmount);
        
        emit TokensSold(msg.sender, tokenAmount, ethAmount);
    }
    
    function getTokenPrice() external view returns (uint256) {
        if (tokenReserves == 0 || ethReserves == 0) return 0;
        return (ethReserves * 1e18) / tokenReserves;
    }
    
    function getEthPrice() external view returns (uint256) {
        if (tokenReserves == 0 || ethReserves == 0) return 0;
        return (tokenReserves * 1e18) / ethReserves;
    }
    
    function getAmountOut(uint256 amountIn, bool buyingTokens) external view returns (uint256) {
        if (tokenReserves == 0 || ethReserves == 0) return 0;
        
        if (buyingTokens) {
            // ETH in, tokens out
            return (amountIn * tokenReserves) / (ethReserves + amountIn);
        } else {
            // Tokens in, ETH out
            return (amountIn * ethReserves) / (tokenReserves + amountIn);
        }
    }
}
