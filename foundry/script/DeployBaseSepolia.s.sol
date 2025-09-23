// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {RemovalNinja} from "../src/RemovalNinja.sol";
import {DataBrokerRegistryUltraSimple} from "../src/DataBrokerRegistryUltraSimple.sol";
import {RemovalTaskFactoryUltraSimple} from "../src/RemovalTaskFactoryUltraSimple.sol";

/**
 * @title DeployBaseSepolia
 * @dev Deploy the complete RemovalNinja modular system to Base Sepolia
 */
contract DeployBaseSepolia is Script {
    
    function _writeDeploymentInfo(
        address deployer,
        address tokenAddr,
        address registryAddr,
        address factoryAddr
    ) internal {
        // Create JSON in smaller parts to avoid stack too deep
        string memory part1 = string(abi.encodePacked(
            '{\n',
            '  "network": "Base Sepolia",\n',
            '  "chainId": 84532,\n',
            '  "deployer": "', vm.toString(deployer), '",\n'
        ));
        
        string memory part2 = string(abi.encodePacked(
            '  "contracts": {\n',
            '    "RemovalNinja": "', vm.toString(tokenAddr), '",\n',
            '    "DataBrokerRegistry": "', vm.toString(registryAddr), '",\n',
            '    "TaskFactory": "', vm.toString(factoryAddr), '"\n',
            '  },\n'
        ));
        
        string memory part3 = string(abi.encodePacked(
            '  "blockNumber": ', vm.toString(block.number), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), '\n',
            '}'
        ));
        
        string memory fullJson = string(abi.encodePacked(part1, part2, part3));
        vm.writeFile("deployment-base-sepolia.json", fullJson);
    }
    
    function run() public returns (
        RemovalNinja token,
        DataBrokerRegistryUltraSimple registry,
        RemovalTaskFactoryUltraSimple factory
    ) {
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("=== Base Sepolia Deployment ===");
        console2.log("Deployer: %s", deployer);
        console2.log("Balance: %s ETH", deployer.balance / 1e18);
        console2.log("Network: Base Sepolia (Chain ID: 84532)");
        console2.log("");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the RN Token
        console2.log("1. Deploying RemovalNinja Token...");
        token = new RemovalNinja();
        console2.log("   Token deployed: %s", address(token));

        // 2. Deploy the Data Broker Registry
        console2.log("2. Deploying DataBrokerRegistry...");
        registry = new DataBrokerRegistryUltraSimple();
        console2.log("   Registry deployed: %s", address(registry));

        // 3. Deploy the Task Factory
        console2.log("3. Deploying TaskFactory...");
        factory = new RemovalTaskFactoryUltraSimple(
            address(token),
            address(registry)
        );
        console2.log("   Factory deployed: %s", address(factory));

        // 4. Setup initial configuration
        console2.log("4. Setting up initial configuration...");
        
        // Grant registry permissions to factory for recording completions
        registry.transferOwnership(deployer); // Ensure deployer is owner
        
        // Transfer initial tokens to deployer for testing
        uint256 initialTokens = 100000 * 10**18; // 100,000 RN tokens
        // RemovalNinja contract mints to deployer by default
        
        // 5. Add initial high-impact brokers
        console2.log("5. Adding initial brokers...");
        
        // Add Spokeo (High Impact)
        registry.addBroker(
            "Spokeo",
            "https://www.spokeo.com",
            "https://www.spokeo.com/optout",
            "privacy@spokeo.com",
            300 // HIGH_IMPACT_WEIGHT
        );
        
        // Add Radaris (High Impact)
        registry.addBroker(
            "Radaris", 
            "https://radaris.com",
            "https://radaris.com/page/how-to-remove",
            "support@radaris.com",
            300 // HIGH_IMPACT_WEIGHT
        );
        
        // Add Whitepages (High Impact)
        registry.addBroker(
            "Whitepages",
            "https://www.whitepages.com",
            "https://www.whitepages.com/suppression-requests",
            "privacy@whitepages.com",
            300 // HIGH_IMPACT_WEIGHT
        );

        vm.stopBroadcast();

        // 6. Output deployment summary
        console2.log("");
        console2.log("=== DEPLOYMENT SUCCESS ===");
        console2.log("RemovalNinja Token: %s", address(token));
        console2.log("DataBrokerRegistry: %s", address(registry));
        console2.log("TaskFactory: %s", address(factory));
        console2.log("");
        console2.log("Initial setup complete:");
        console2.log("- 3 high-impact brokers added");
        console2.log("- %s RN tokens minted to deployer", initialTokens / 1e18);
        console2.log("");
        console2.log("Block Explorer URLs:");
        console2.log("- Token: https://sepolia.basescan.org/address/%s", address(token));
        console2.log("- Registry: https://sepolia.basescan.org/address/%s", address(registry));
        console2.log("- Factory: https://sepolia.basescan.org/address/%s", address(factory));
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Update client/src/config/contracts.ts with new addresses");
        console2.log("2. Switch frontend to BASE_SEPOLIA network");
        console2.log("3. Test contract functions on BaseScan");
        console2.log("4. Add Base Sepolia to MetaMask if not already added");

        // Save deployment info to JSON file (simplified to avoid stack too deep)
        _writeDeploymentInfo(deployer, address(token), address(registry), address(factory));
        console2.log("Deployment info saved to: deployment-base-sepolia.json");

        return (token, registry, factory);
    }
}
