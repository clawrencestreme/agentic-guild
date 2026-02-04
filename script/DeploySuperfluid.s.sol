// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuild.sol";

/**
 * @title DeploySuperfluid
 * @notice Deploy AgenticGuild with real Superfluid GDA on Base Sepolia
 * 
 * Uses existing Superfluid test tokens:
 * - fUSDC: 0x6B0dacea6a72E759243c99Eaed840DEe9564C194
 * - fUSDCx: 0x1650581F573eAd727B92073B5Ef8B4f5B94D1648
 */
contract DeploySuperfluid is Script {
    // Base Sepolia Superfluid
    address constant SUPERFLUID_HOST = 0x109412E3C84f0539b43d39dB691B08c90f58dC7c;
    address constant GDA_FORWARDER = 0x6DA13Bde224A05a288748d857b9e7DDEffd1dE08;
    
    // Existing test tokens
    address constant FUSDC = 0x6B0dacea6a72E759243c99Eaed840DEe9564C194;
    address constant FUSDCX = 0x1650581F573eAd727B92073B5Ef8B4f5B94D1648;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        console.log("Deployer:", deployer);
        console.log("Deploying AgenticGuild with Superfluid GDA...");
        
        vm.startBroadcast(deployerKey);
        
        // Deploy AgenticGuild
        AgenticGuild guild = new AgenticGuild(
            FUSDC,
            FUSDCX,
            SUPERFLUID_HOST,
            GDA_FORWARDER
        );
        console.log("AgenticGuild deployed:", address(guild));
        
        // Initialize the Superfluid pool
        guild.initializePool();
        console.log("GDA Pool initialized");
        
        // Add deployer as judge
        guild.addJudge(deployer);
        console.log("Deployer added as judge");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("AgenticGuild:", address(guild));
        console.log("fUSDC:", FUSDC);
        console.log("fUSDCx:", FUSDCX);
        console.log("\nNext: Fund with fUSDCx and set flow rate");
    }
}
