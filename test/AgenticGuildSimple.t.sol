// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AgenticGuildSimple.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDC for testing
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AgenticGuildSimpleTest is Test {
    AgenticGuildSimple public guild;
    MockUSDC public usdc;
    
    address public owner = address(this);
    address public judge1 = address(0x1);
    address public judge2 = address(0x2);
    address public judge3 = address(0x3);
    address public builder1 = address(0x10);
    address public builder2 = address(0x20);
    address public builder3 = address(0x30);
    address public funder = address(0x100);
    
    uint256 constant STAKE = 100e6; // 100 USDC
    
    function setUp() public {
        usdc = new MockUSDC();
        guild = new AgenticGuildSimple(address(usdc));
        
        // Mint USDC to test accounts
        usdc.mint(builder1, 1000e6);
        usdc.mint(builder2, 1000e6);
        usdc.mint(builder3, 1000e6);
        usdc.mint(funder, 10000e6);
        
        // Approve guild
        vm.prank(builder1);
        usdc.approve(address(guild), type(uint256).max);
        vm.prank(builder2);
        usdc.approve(address(guild), type(uint256).max);
        vm.prank(builder3);
        usdc.approve(address(guild), type(uint256).max);
        vm.prank(funder);
        usdc.approve(address(guild), type(uint256).max);
    }
    
    function test_AddJudge() public {
        guild.addJudge(judge1);
        assertTrue(guild.isJudge(judge1));
        
        address[] memory judges = guild.getJudges();
        assertEq(judges.length, 1);
        assertEq(judges[0], judge1);
    }
    
    function test_AddMultipleJudges() public {
        guild.addJudge(judge1);
        guild.addJudge(judge2);
        guild.addJudge(judge3);
        
        address[] memory judges = guild.getJudges();
        assertEq(judges.length, 3);
    }
    
    function test_RemoveJudge() public {
        guild.addJudge(judge1);
        guild.addJudge(judge2);
        
        guild.removeJudge(judge1);
        
        assertFalse(guild.isJudge(judge1));
        address[] memory judges = guild.getJudges();
        assertEq(judges.length, 1);
        assertEq(judges[0], judge2);
    }
    
    function test_BuilderJoin() public {
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        assertTrue(guild.isBuilder(builder1));
        assertEq(guild.builderStake(builder1), STAKE);
        assertEq(usdc.balanceOf(address(guild)), STAKE);
        
        address[] memory builders = guild.getBuilders();
        assertEq(builders.length, 1);
        assertEq(builders[0], builder1);
    }
    
    function test_JudgeCannotBeBuilder() public {
        guild.addJudge(judge1);
        
        usdc.mint(judge1, 1000e6);
        vm.prank(judge1);
        usdc.approve(address(guild), type(uint256).max);
        
        vm.prank(judge1);
        vm.expectRevert("Judges cannot be builders");
        guild.joinAsBuilder();
    }
    
    function test_Vote() public {
        guild.addJudge(judge1);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        vm.prank(builder2);
        guild.joinAsBuilder();
        
        address[] memory targets = new address[](2);
        targets[0] = builder1;
        targets[1] = builder2;
        
        uint256[] memory points = new uint256[](2);
        points[0] = 70;
        points[1] = 30;
        
        vm.prank(judge1);
        guild.vote(targets, points);
        
        assertEq(guild.getScore(builder1), 70);
        assertEq(guild.getScore(builder2), 30);
    }
    
    function test_VoteMustSumTo100() public {
        guild.addJudge(judge1);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        address[] memory targets = new address[](1);
        targets[0] = builder1;
        
        uint256[] memory points = new uint256[](1);
        points[0] = 50; // Not 100
        
        vm.prank(judge1);
        vm.expectRevert("Must allocate 100 points");
        guild.vote(targets, points);
    }
    
    function test_MultipleJudgesVote() public {
        guild.addJudge(judge1);
        guild.addJudge(judge2);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        vm.prank(builder2);
        guild.joinAsBuilder();
        
        // Judge 1 votes
        address[] memory targets1 = new address[](2);
        targets1[0] = builder1;
        targets1[1] = builder2;
        uint256[] memory points1 = new uint256[](2);
        points1[0] = 80;
        points1[1] = 20;
        
        vm.prank(judge1);
        guild.vote(targets1, points1);
        
        // Judge 2 votes
        address[] memory targets2 = new address[](2);
        targets2[0] = builder1;
        targets2[1] = builder2;
        uint256[] memory points2 = new uint256[](2);
        points2[0] = 40;
        points2[1] = 60;
        
        vm.prank(judge2);
        guild.vote(targets2, points2);
        
        // Scores: builder1 = 80+40=120, builder2 = 20+60=80
        assertEq(guild.getScore(builder1), 120);
        assertEq(guild.getScore(builder2), 80);
    }
    
    function test_Distribution() public {
        guild.addJudge(judge1);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        vm.prank(builder2);
        guild.joinAsBuilder();
        
        // Fund the guild
        vm.prank(funder);
        guild.fund(1000e6); // 1000 USDC
        
        // Judge votes
        address[] memory targets = new address[](2);
        targets[0] = builder1;
        targets[1] = builder2;
        uint256[] memory points = new uint256[](2);
        points[0] = 75;
        points[1] = 25;
        
        vm.prank(judge1);
        guild.vote(targets, points);
        
        // Distribute
        guild.distribute();
        
        // builder1 should get 75% = 750 USDC
        // builder2 should get 25% = 250 USDC
        assertEq(guild.getPendingClaim(builder1), 750e6);
        assertEq(guild.getPendingClaim(builder2), 250e6);
    }
    
    function test_Claim() public {
        guild.addJudge(judge1);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        vm.prank(funder);
        guild.fund(500e6);
        
        address[] memory targets = new address[](1);
        targets[0] = builder1;
        uint256[] memory points = new uint256[](1);
        points[0] = 100;
        
        vm.prank(judge1);
        guild.vote(targets, points);
        
        guild.distribute();
        
        uint256 balanceBefore = usdc.balanceOf(builder1);
        
        vm.prank(builder1);
        guild.claim();
        
        assertEq(usdc.balanceOf(builder1), balanceBefore + 500e6);
        assertEq(guild.getPendingClaim(builder1), 0);
    }
    
    function test_ExitCooldown() public {
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        vm.prank(builder1);
        guild.initiateExit();
        
        // Try to complete immediately - should fail
        vm.prank(builder1);
        vm.expectRevert("Cooldown not complete");
        guild.completeExit();
        
        // Warp time
        vm.warp(block.timestamp + 7 days);
        
        // Now should work
        vm.prank(builder1);
        guild.completeExit();
        
        assertFalse(guild.isBuilder(builder1));
        assertEq(usdc.balanceOf(builder1), 1000e6); // Original balance restored
    }
    
    function test_ExitWithPendingClaims() public {
        guild.addJudge(judge1);
        
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        vm.prank(funder);
        guild.fund(500e6);
        
        address[] memory targets = new address[](1);
        targets[0] = builder1;
        uint256[] memory points = new uint256[](1);
        points[0] = 100;
        
        vm.prank(judge1);
        guild.vote(targets, points);
        
        guild.distribute();
        
        // Initiate exit
        vm.prank(builder1);
        guild.initiateExit();
        
        vm.warp(block.timestamp + 7 days);
        
        // Complete exit - should get stake + pending
        vm.prank(builder1);
        guild.completeExit();
        
        // Should have: original 1000 - 100 stake + 100 stake back + 500 rewards = 1500
        assertEq(usdc.balanceOf(builder1), 1500e6);
    }
    
    function test_NonJudgeCannotVote() public {
        vm.prank(builder1);
        guild.joinAsBuilder();
        
        address[] memory targets = new address[](1);
        targets[0] = builder1;
        uint256[] memory points = new uint256[](1);
        points[0] = 100;
        
        vm.prank(builder2); // Not a judge
        vm.expectRevert("Not a judge");
        guild.vote(targets, points);
    }
    
    function test_EqualDistributionWithNoVotes() public {
        vm.prank(builder1);
        guild.joinAsBuilder();
        vm.prank(builder2);
        guild.joinAsBuilder();
        
        vm.prank(funder);
        guild.fund(1000e6);
        
        // No votes cast
        guild.distribute();
        
        // Should distribute equally (500 each)
        assertEq(guild.getPendingClaim(builder1), 500e6);
        assertEq(guild.getPendingClaim(builder2), 500e6);
    }
}
