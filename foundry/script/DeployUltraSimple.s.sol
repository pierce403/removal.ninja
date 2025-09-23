// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import {RemovalNinja} from "../src/RemovalNinja.sol";
import {DataBrokerRegistryUltraSimple} from "../src/DataBrokerRegistryUltraSimple.sol";
import {RemovalTaskFactoryUltraSimple} from "../src/RemovalTaskFactoryUltraSimple.sol";

/**
 * @title DeployUltraSimple
 * @dev Deploy the ultra-simplified RemovalNinja system
 */
contract DeployUltraSimple is Script {
    function run() public returns (
        RemovalNinja token,
        DataBrokerRegistryUltraSimple registry,
        RemovalTaskFactoryUltraSimple factory
    ) {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // Default Anvil key
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Deployer: %s", deployer);
        console2.log("Deploying Ultra-Simple RemovalNinja System...");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy token
        token = new RemovalNinja();
        console2.log("Token: %s", address(token));

        // Deploy registry
        registry = new DataBrokerRegistryUltraSimple();
        console2.log("Registry: %s", address(registry));

        // Deploy factory
        factory = new RemovalTaskFactoryUltraSimple(
            address(token),
            address(registry)
        );
        console2.log("Factory: %s", address(factory));

        // Add test brokers
        registry.addBroker(
            "Spokeo",
            "https://www.spokeo.com",
            "https://www.spokeo.com/optout",
            "privacy@spokeo.com",
            300
        );
        
        registry.addBroker(
            "Radaris",
            "https://radaris.com",
            "https://radaris.com/page/how-to-remove",
            "support@radaris.com",
            300
        );

        vm.stopBroadcast();

        console2.log("Deployment complete!");
        console2.log("Added 2 test brokers");

        return (token, registry, factory);
    }
}
