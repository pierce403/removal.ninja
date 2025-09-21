// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {RemovalNinja} from "../src/RemovalNinja.sol";

/**
 * @title Deploy RemovalNinja to Base Sepolia Testnet
 * @dev Deployment script for Base testnet with proper verification
 */
contract DeployBase is Script {
    RemovalNinja public removalNinja;
    
    function setUp() public {}
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying RemovalNinja contract...");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the RemovalNinja contract
        removalNinja = new RemovalNinja();
        
        vm.stopBroadcast();
        
        console.log("RemovalNinja deployed to:", address(removalNinja));
        console.log("Contract owner:", removalNinja.owner());
        console.log("Initial token supply:", removalNinja.totalSupply());
        console.log("Deployer token balance:", removalNinja.balanceOf(deployer));
        
        // Log deployment info for frontend integration
        console.log("\n=== Frontend Integration ===");
        console.log("Contract Address:", address(removalNinja));
        console.log("Network: Base Sepolia");
        console.log("Chain ID: 84532");
        console.log("Block Explorer: https://sepolia.basescan.org/address/%s", address(removalNinja));
        
        // Log contract verification command
        console.log("\n=== Contract Verification ===");
        console.log("Run this command to verify the contract:");
        console.log("forge verify-contract %s src/RemovalNinja.sol:RemovalNinja --chain base-sepolia --etherscan-api-key $BASESCAN_API_KEY", address(removalNinja));
        
        // Save deployment info to file
        string memory deploymentInfo = string(abi.encodePacked(
            '{\n',
            '  "contractAddress": "', vm.toString(address(removalNinja)), '",\n',
            '  "network": "Base Sepolia",\n',
            '  "chainId": 84532,\n',
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "blockNumber": ', vm.toString(block.number), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}'
        ));
        
        vm.writeFile("./deployment-base-sepolia.json", deploymentInfo);
        console.log("\nDeployment info saved to deployment-base-sepolia.json");
    }
}
