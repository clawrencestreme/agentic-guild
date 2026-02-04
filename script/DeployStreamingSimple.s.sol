// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuildStreaming.sol";
import "../src/MockUSDC.sol";

/**
 * @title DeployStreamingSimple
 * @notice Deploy AgenticGuildStreaming with simple streaming rewards
 */
contract DeployStreamingSimple is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        console.log("Deployer:", deployer);
        console.log("Deploying AgenticGuildStreaming to Base Sepolia...");
        
        vm.startBroadcast(deployerKey);
        
        // 1. Deploy MockUSDC
        MockUSDC mockUsdc = new MockUSDC();
        console.log("MockUSDC deployed:", address(mockUsdc));
        
        // 2. Deploy AgenticGuildStreaming
        AgenticGuildStreaming guild = new AgenticGuildStreaming(address(mockUsdc));
        console.log("AgenticGuildStreaming deployed:", address(guild));
        
        // 3. Add deployer as a judge
        guild.addJudge(deployer);
        console.log("Deployer added as judge");
        
        // 4. Mint USDC for testing
        mockUsdc.mint(deployer, 1_000_000e6); // 1M USDC
        console.log("Minted 1M USDC to deployer");
        
        // 5. Fund the guild with 100k USDC
        mockUsdc.approve(address(guild), 100_000e6);
        guild.fund(100_000e6);
        console.log("Funded guild with 100k USDC");
        
        // 6. Set flow rate: 1 USDC per second (~86,400 USDC/day)
        guild.setFlowRate(1e6); // 1 USDC/sec
        console.log("Flow rate set to 1 USDC/second");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("MockUSDC:", address(mockUsdc));
        console.log("AgenticGuildStreaming:", address(guild));
        console.log("\nStreaming is LIVE!");
        console.log("- Treasury: 100,000 USDC");
        console.log("- Flow rate: 1 USDC/second");
        console.log("- Register builders, vote, and watch rewards stream!");
    }
}
