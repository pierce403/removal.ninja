// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {RemovalNinja} from "../src/RemovalNinja.sol";
import {DataBrokerRegistrySimple} from "../src/DataBrokerRegistrySimple.sol";
import {RemovalTaskFactorySimple} from "../src/RemovalTaskFactorySimple.sol";

/**
 * @title DeploySimpleSystem
 * @dev Deploy the simplified RemovalNinja modular system
 * @author Pierce
 */
contract DeploySimpleSystem is Script {
    function run() public returns (
        RemovalNinja removalNinjaToken,
        DataBrokerRegistrySimple dataBrokerRegistry,
        RemovalTaskFactorySimple taskFactory
    ) {
        // Load the private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer address: %s", deployer);
        console2.log("Deploying RemovalNinja Simple System...");

        // Start broadcasting transactions from the deployer address
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy the RN Token (RemovalNinja contract)
        console2.log("1. Deploying RemovalNinja Token...");
        removalNinjaToken = new RemovalNinja();
        console2.log("RemovalNinja Token deployed to: %s", address(removalNinjaToken));

        // 2. Deploy the Data Broker Registry
        console2.log("2. Deploying DataBrokerRegistrySimple...");
        dataBrokerRegistry = new DataBrokerRegistrySimple();
        console2.log("DataBrokerRegistrySimple deployed to: %s", address(dataBrokerRegistry));

        // 3. Deploy the Task Factory
        console2.log("3. Deploying RemovalTaskFactorySimple...");
        taskFactory = new RemovalTaskFactorySimple(
            address(removalNinjaToken),     // Payment token (RN)
            address(dataBrokerRegistry),    // Data broker registry
            deployer                        // Platform treasury (deployer for now)
        );
        console2.log("RemovalTaskFactorySimple deployed to: %s", address(taskFactory));

        // 4. Setup initial permissions and configuration
        console2.log("4. Setting up initial configuration...");
        
        // Grant broker manager role to task factory for recording completions
        // (This allows the factory to record successful removals)
        dataBrokerRegistry.grantRole(dataBrokerRegistry.BROKER_MANAGER_ROLE(), address(taskFactory));
        
        // Transfer some initial tokens to the deployer for testing
        uint256 initialTokens = 100000 * 10**18; // 100,000 RN tokens
        removalNinjaToken.transfer(deployer, initialTokens);
        
        // 5. Add some initial high-impact brokers for testing
        console2.log("5. Adding initial high-impact brokers...");
        
        // Add Spokeo
        dataBrokerRegistry.addBroker(
            "Spokeo",
            "https://www.spokeo.com",
            "https://www.spokeo.com/optout",
            "https://www.spokeo.com/privacy-policy",
            "privacy@spokeo.com",
            "Full name, age, current address",
            "High-impact removal. Process takes 72 hours. May require phone verification.",
            "high-impact,people-search,public-records",
            300 // HIGH_IMPACT_WEIGHT
        );
        
        // Add Radaris
        dataBrokerRegistry.addBroker(
            "Radaris",
            "https://radaris.com",
            "https://radaris.com/page/how-to-remove",
            "https://radaris.com/page/privacy",
            "support@radaris.com",
            "Full name, current address, phone number",
            "High-impact removal. May require multiple attempts. Check for reappearance.",
            "high-impact,people-search,public-records",
            300 // HIGH_IMPACT_WEIGHT
        );
        
        // Add Whitepages
        dataBrokerRegistry.addBroker(
            "Whitepages",
            "https://www.whitepages.com",
            "https://www.whitepages.com/suppression-requests",
            "https://www.whitepages.com/privacy",
            "privacy@whitepages.com",
            "URL of listing, phone number verification",
            "High-impact removal. Must verify phone number via SMS.",
            "high-impact,people-search,phone-directory",
            300 // HIGH_IMPACT_WEIGHT
        );

        vm.stopBroadcast();

        console2.log("");
        console2.log("=== Deployment Summary ===");
        console2.log("RemovalNinja Token: %s", address(removalNinjaToken));
        console2.log("DataBrokerRegistry: %s", address(dataBrokerRegistry));
        console2.log("TaskFactory: %s", address(taskFactory));
        console2.log("");
        console2.log("Initial tokens distributed to deployer: 100,000 RN");
        console2.log("Initial brokers added: 3 (Spokeo, Radaris, Whitepages)");
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Workers can register with the TaskFactory");
        console2.log("2. Users can create removal tasks");
        console2.log("3. More brokers can be added to the registry");

        return (removalNinjaToken, dataBrokerRegistry, taskFactory);
    }
}
