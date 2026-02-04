// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuildSimple.sol";

contract DeployScript is Script {
    // Base Sepolia USDC
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    
    // Base Mainnet USDC
    address constant USDC_BASE_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Determine which USDC to use based on chain
        address usdc;
        if (block.chainid == 84532) {
            usdc = USDC_BASE_SEPOLIA;
            console.log("Deploying to Base Sepolia");
        } else if (block.chainid == 8453) {
            usdc = USDC_BASE_MAINNET;
            console.log("Deploying to Base Mainnet");
        } else {
            revert("Unsupported chain");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        AgenticGuildSimple guild = new AgenticGuildSimple(usdc);
        
        console.log("AgenticGuildSimple deployed at:", address(guild));
        console.log("USDC address:", usdc);
        
        vm.stopBroadcast();
    }
}

contract SetupJudgesScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address guildAddress = vm.envAddress("GUILD_ADDRESS");
        
        // Add judges - replace with actual judge addresses
        address[] memory judges = new address[](3);
        judges[0] = vm.envAddress("JUDGE_1");
        judges[1] = vm.envAddress("JUDGE_2");
        judges[2] = vm.envAddress("JUDGE_3");
        
        vm.startBroadcast(deployerPrivateKey);
        
        AgenticGuildSimple guild = AgenticGuildSimple(guildAddress);
        
        for (uint i = 0; i < judges.length; i++) {
            if (judges[i] != address(0) && !guild.isJudge(judges[i])) {
                guild.addJudge(judges[i]);
                console.log("Added judge:", judges[i]);
            }
        }
        
        vm.stopBroadcast();
    }
}
