// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuildSimple.sol";
import "../src/MockUSDC.sol";

/**
 * @title DeployDemo
 * @notice Deploy guild + mock USDC for hackathon demo on Base Sepolia
 */
contract DeployDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy Mock USDC
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));
        
        // 2. Deploy Guild
        AgenticGuildSimple guild = new AgenticGuildSimple(address(usdc));
        console.log("AgenticGuild deployed at:", address(guild));
        
        // 3. Add deployer as a judge (for demo)
        guild.addJudge(deployer);
        console.log("Added deployer as judge");
        
        // 4. Approve guild to spend USDC
        usdc.approve(address(guild), type(uint256).max);
        console.log("Approved guild for USDC");
        
        // 5. Fund guild treasury with 10,000 USDC
        guild.fund(10_000e6);
        console.log("Funded guild with 10,000 USDC");
        
        vm.stopBroadcast();
        
        console.log("");
        console.log("=== DEPLOYMENT COMPLETE ===");
        console.log("MockUSDC:", address(usdc));
        console.log("AgenticGuild:", address(guild));
        console.log("");
        console.log("Next steps:");
        console.log("1. Create builder wallets and mint them USDC");
        console.log("2. Have builders call joinAsBuilder()");
        console.log("3. Cast votes with vote()");
        console.log("4. Call distribute() to send rewards");
    }
}

/**
 * @title DemoTransactions
 * @notice Run demo transactions after deployment
 */
contract DemoTransactions is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address guild = vm.envAddress("GUILD");
        address usdc = vm.envAddress("USDC");
        
        // Demo builder addresses (we'll use deterministic addresses)
        address builder1 = address(0x1111111111111111111111111111111111111111);
        address builder2 = address(0x2222222222222222222222222222222222222222);
        address builder3 = address(0x3333333333333333333333333333333333333333);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Mint USDC to builders
        MockUSDC(usdc).mint(builder1, 1000e6);
        MockUSDC(usdc).mint(builder2, 1000e6);
        MockUSDC(usdc).mint(builder3, 1000e6);
        console.log("Minted USDC to builders");
        
        vm.stopBroadcast();
        
        // Now simulate builders joining (would need their private keys in real scenario)
        // For demo, we show the flow
        
        console.log("");
        console.log("Demo builder addresses:");
        console.log("Builder 1:", builder1);
        console.log("Builder 2:", builder2);
        console.log("Builder 3:", builder3);
    }
}
