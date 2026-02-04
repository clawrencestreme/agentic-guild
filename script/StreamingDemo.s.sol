// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuildStreaming.sol";
import "../src/MockUSDC.sol";

/**
 * @title StreamingDemo
 * @notice Demo the streaming rewards in action
 */
contract StreamingDemo is Script {
    function run() external {
        // Load deployed contracts
        MockUSDC usdc = MockUSDC(0x3790f29015609f7aC2d323914EE8d9E062a59bC3);
        AgenticGuildStreaming guild = AgenticGuildStreaming(0x82B190bD47146991F1917c266b600Dd18b6D74F7);
        
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        // Create builder keypairs
        uint256 builder1Key = 0x1111111111111111111111111111111111111111111111111111111111111111;
        uint256 builder2Key = 0x2222222222222222222222222222222222222222222222222222222222222222;
        uint256 builder3Key = 0x3333333333333333333333333333333333333333333333333333333333333333;
        
        address builder1 = vm.addr(builder1Key);
        address builder2 = vm.addr(builder2Key);
        address builder3 = vm.addr(builder3Key);
        
        console.log("\n=== STREAMING DEMO ===\n");
        console.log("Builder 1:", builder1);
        console.log("Builder 2:", builder2);
        console.log("Builder 3:", builder3);
        
        // Step 1: Fund builders
        console.log("\n1. Funding builders with USDC...");
        vm.startBroadcast(deployerKey);
        usdc.mint(builder1, 200e6);
        usdc.mint(builder2, 200e6);
        usdc.mint(builder3, 200e6);
        vm.stopBroadcast();
        
        // Step 2: Builders register
        console.log("2. Builders registering (staking 100 USDC each)...");
        
        vm.startBroadcast(builder1Key);
        usdc.approve(address(guild), 100e6);
        guild.joinAsBuilder();
        vm.stopBroadcast();
        
        vm.startBroadcast(builder2Key);
        usdc.approve(address(guild), 100e6);
        guild.joinAsBuilder();
        vm.stopBroadcast();
        
        vm.startBroadcast(builder3Key);
        usdc.approve(address(guild), 100e6);
        guild.joinAsBuilder();
        vm.stopBroadcast();
        
        console.log("   Registered: 3 builders");
        
        // Step 3: Judge votes
        console.log("3. Judge voting (50/30/20 split)...");
        address[] memory targets = new address[](3);
        uint256[] memory points = new uint256[](3);
        targets[0] = builder1;
        targets[1] = builder2;
        targets[2] = builder3;
        points[0] = 50;
        points[1] = 30;
        points[2] = 20;
        
        vm.startBroadcast(deployerKey);
        guild.vote(targets, points);
        vm.stopBroadcast();
        
        console.log("   Builder 1: 50 points (50% of stream)");
        console.log("   Builder 2: 30 points (30% of stream)");
        console.log("   Builder 3: 20 points (20% of stream)");
        
        // Step 4: Check streaming rates
        console.log("\n4. Streaming Rates:");
        console.log("   Total flow: 1 USDC/second");
        console.log("   Builder 1 rate:", guild.getBuilderFlowRate(builder1), "USDC/sec (0.5)");
        console.log("   Builder 2 rate:", guild.getBuilderFlowRate(builder2), "USDC/sec (0.3)");
        console.log("   Builder 3 rate:", guild.getBuilderFlowRate(builder3), "USDC/sec (0.2)");
        
        // Step 5: Check pending rewards
        console.log("\n5. Pending Rewards (after a few seconds):");
        console.log("   Builder 1:", guild.getPendingRewards(builder1));
        console.log("   Builder 2:", guild.getPendingRewards(builder2));
        console.log("   Builder 3:", guild.getPendingRewards(builder3));
        
        // Step 6: Builder 1 claims
        console.log("\n6. Builder 1 claiming rewards...");
        uint256 balanceBefore = usdc.balanceOf(builder1);
        
        vm.startBroadcast(builder1Key);
        guild.claimRewards();
        vm.stopBroadcast();
        
        uint256 claimed = usdc.balanceOf(builder1) - balanceBefore;
        console.log("   Claimed:", claimed, "USDC");
        
        console.log("\n=== DEMO COMPLETE ===");
        console.log("Treasury remaining:", guild.getTreasuryBalance());
    }
}
