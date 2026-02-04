// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/AgenticGuild.sol";
import "../src/MockUSDC.sol";
import "../src/interfaces/ISuperfluid.sol";

/**
 * @title DeployStreaming
 * @notice Deploy the streaming version of AgenticGuild with Superfluid
 * 
 * Base Sepolia Superfluid addresses:
 * - Host: 0x109412E3C84f0539b43d39dB691B08c90f58dC7c
 * - GDA: 0x53F4f44C813Dc380182d0b2b67fe5832A12B97f8
 * - SuperTokenFactory: 0x7447E94Dfe3d804a9f46Bf12838d467c909C8F6C
 */
contract DeployStreaming is Script {
    // Base Sepolia Superfluid
    address constant SUPERFLUID_HOST = 0x109412E3C84f0539b43d39dB691B08c90f58dC7c;
    address constant SUPER_TOKEN_FACTORY = 0x7447E94Dfe3d804a9f46Bf12838d467c912C8F6C;
    address constant GDA_FORWARDER = 0x6DA13Bde224A05a288748d857b9e7DDEffd1dE08;
    
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);
        
        console.log("Deployer:", deployer);
        console.log("Deploying streaming AgenticGuild to Base Sepolia...");
        
        vm.startBroadcast(deployerKey);
        
        // 1. Deploy MockUSDC
        MockUSDC mockUsdc = new MockUSDC();
        console.log("MockUSDC deployed:", address(mockUsdc));
        
        // 2. Create SuperToken wrapper using factory
        // We need to call createERC20Wrapper on the SuperTokenFactory
        ISuperTokenFactory factory = ISuperTokenFactory(SUPER_TOKEN_FACTORY);
        
        // Create wrapper with upgradability (1 = SEMI_UPGRADABLE)
        // Note: underlyingDecimals should match the underlying token (6 for USDC)
        ISuperToken usdcx = factory.createERC20Wrapper(
            address(mockUsdc),
            6, // MockUSDC has 6 decimals
            ISuperTokenFactory.Upgradability.SEMI_UPGRADABLE,
            "Super Mock USDC",
            "USDCx"
        );
        console.log("USDCx (SuperToken) deployed:", address(usdcx));
        
        // 3. Deploy AgenticGuild
        AgenticGuild guild = new AgenticGuild(
            address(mockUsdc),
            address(usdcx),
            SUPERFLUID_HOST,
            GDA_FORWARDER
        );
        console.log("AgenticGuild deployed:", address(guild));
        
        // 4. Initialize the pool
        guild.initializePool();
        console.log("Pool initialized");
        
        // 5. Add deployer as a judge
        guild.addJudge(deployer);
        console.log("Deployer added as judge");
        
        // 6. Mint some USDC for testing
        mockUsdc.mint(deployer, 100_000e6); // 100k USDC
        console.log("Minted 100k USDC to deployer");
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("MockUSDC:", address(mockUsdc));
        console.log("USDCx:", address(usdcx));
        console.log("AgenticGuild:", address(guild));
        console.log("\nNext steps:");
        console.log("1. Approve USDC and wrap to USDCx");
        console.log("2. Fund the guild treasury");
        console.log("3. Set flow rate");
        console.log("4. Add builders and start voting!");
    }
}

// Interfaces for SuperTokenFactory
interface ISuperTokenFactory {
    enum Upgradability {
        NON_UPGRADABLE,
        SEMI_UPGRADABLE,
        FULL_UPGRADABLE
    }
    
    function createERC20Wrapper(
        address underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string memory name,
        string memory symbol
    ) external returns (ISuperToken superToken);
}
