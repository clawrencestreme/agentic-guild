// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AgenticGuildSimple
 * @notice Simplified version without Superfluid - uses periodic distributions
 * @dev For testing and networks without Superfluid support
 * 
 * Instead of streaming, this version accumulates funds and distributes
 * proportionally when distribute() is called.
 */
contract AgenticGuildSimple is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Constants ============
    uint256 public constant STAKE_AMOUNT = 100e6; // 100 USDC (6 decimals)
    uint256 public constant VOTE_POINTS = 100;    // Each judge has 100 points
    uint256 public constant MIN_SHARE = 100;      // Minimum share for any builder
    uint256 public constant EXIT_COOLDOWN = 7 days;

    // ============ State ============
    
    IERC20 public immutable usdc;
    
    // Judges
    mapping(address => bool) public isJudge;
    address[] public judges;
    
    // Builders
    mapping(address => bool) public isBuilder;
    mapping(address => uint256) public builderStake;
    mapping(address => uint256) public exitInitiatedAt;
    address[] public builders;
    
    // Voting
    struct Vote {
        address[] targets;
        uint256[] points;
        uint256 timestamp;
    }
    mapping(address => Vote) public judgeVotes;
    
    // Distribution tracking
    mapping(address => uint256) public pendingClaims;
    uint256 public totalDistributable;
    uint256 public lastDistributionTime;

    // ============ Events ============
    
    event JudgeAdded(address indexed judge);
    event JudgeRemoved(address indexed judge);
    event BuilderJoined(address indexed builder, uint256 stake);
    event BuilderExitInitiated(address indexed builder);
    event BuilderExited(address indexed builder, uint256 stakeReturned);
    event VoteCast(address indexed judge, address[] targets, uint256[] points);
    event DistributionExecuted(uint256 amount, uint256 timestamp);
    event Claimed(address indexed builder, uint256 amount);
    event TreasuryFunded(address indexed funder, uint256 amount);

    // ============ Constructor ============
    
    constructor(address _usdc) Ownable(msg.sender) {
        usdc = IERC20(_usdc);
    }
    
    // ============ Admin Functions ============
    
    function addJudge(address judge) external onlyOwner {
        require(!isJudge[judge], "Already a judge");
        require(!isBuilder[judge], "Cannot be both");
        
        isJudge[judge] = true;
        judges.push(judge);
        
        emit JudgeAdded(judge);
    }
    
    function removeJudge(address judge) external onlyOwner {
        require(isJudge[judge], "Not a judge");
        
        isJudge[judge] = false;
        _removeFromArray(judges, judge);
        delete judgeVotes[judge];
        
        emit JudgeRemoved(judge);
    }
    
    function fund(uint256 amount) external nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        totalDistributable += amount;
        
        emit TreasuryFunded(msg.sender, amount);
    }
    
    // ============ Builder Functions ============
    
    function joinAsBuilder() external nonReentrant {
        require(!isBuilder[msg.sender], "Already a builder");
        require(!isJudge[msg.sender], "Judges cannot be builders");
        
        usdc.safeTransferFrom(msg.sender, address(this), STAKE_AMOUNT);
        
        isBuilder[msg.sender] = true;
        builderStake[msg.sender] = STAKE_AMOUNT;
        builders.push(msg.sender);
        
        emit BuilderJoined(msg.sender, STAKE_AMOUNT);
    }
    
    function initiateExit() external {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] == 0, "Exit already initiated");
        
        exitInitiatedAt[msg.sender] = block.timestamp;
        
        emit BuilderExitInitiated(msg.sender);
    }
    
    function completeExit() external nonReentrant {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] != 0, "Exit not initiated");
        require(
            block.timestamp >= exitInitiatedAt[msg.sender] + EXIT_COOLDOWN,
            "Cooldown not complete"
        );
        
        // Claim any pending rewards first
        uint256 pending = pendingClaims[msg.sender];
        uint256 stake = builderStake[msg.sender];
        uint256 total = stake + pending;
        
        // Clean up
        isBuilder[msg.sender] = false;
        builderStake[msg.sender] = 0;
        exitInitiatedAt[msg.sender] = 0;
        pendingClaims[msg.sender] = 0;
        _removeFromArray(builders, msg.sender);
        
        usdc.safeTransfer(msg.sender, total);
        
        emit BuilderExited(msg.sender, total);
    }
    
    function claim() external nonReentrant {
        require(isBuilder[msg.sender], "Not a builder");
        
        uint256 amount = pendingClaims[msg.sender];
        require(amount > 0, "Nothing to claim");
        
        pendingClaims[msg.sender] = 0;
        usdc.safeTransfer(msg.sender, amount);
        
        emit Claimed(msg.sender, amount);
    }
    
    // ============ Judge Functions ============
    
    function vote(address[] calldata targets, uint256[] calldata points) external {
        require(isJudge[msg.sender], "Not a judge");
        require(targets.length == points.length, "Length mismatch");
        require(targets.length > 0, "Must vote for someone");
        
        uint256 totalPoints = 0;
        for (uint i = 0; i < points.length; i++) {
            require(isBuilder[targets[i]], "Not a builder");
            require(exitInitiatedAt[targets[i]] == 0, "Builder exiting");
            totalPoints += points[i];
        }
        require(totalPoints == VOTE_POINTS, "Must allocate 100 points");
        
        // Check duplicates
        for (uint i = 0; i < targets.length; i++) {
            for (uint j = i + 1; j < targets.length; j++) {
                require(targets[i] != targets[j], "Duplicate");
            }
        }
        
        judgeVotes[msg.sender] = Vote({
            targets: targets,
            points: points,
            timestamp: block.timestamp
        });
        
        emit VoteCast(msg.sender, targets, points);
    }
    
    // ============ Distribution ============
    
    /**
     * @notice Distribute accumulated funds to builders based on votes
     * @dev Can be called by anyone - distributes totalDistributable
     */
    function distribute() external {
        require(totalDistributable > 0, "Nothing to distribute");
        require(builders.length > 0, "No builders");
        
        uint256 amountToDistribute = totalDistributable;
        totalDistributable = 0;
        
        // Calculate scores
        uint256[] memory scores = new uint256[](builders.length);
        uint256 totalScore = 0;
        uint256 activeBuilders = 0;
        
        for (uint i = 0; i < builders.length; i++) {
            if (exitInitiatedAt[builders[i]] == 0) {
                scores[i] = _calculateScore(builders[i]);
                totalScore += scores[i];
                activeBuilders++;
            }
        }
        
        // If no votes, distribute equally
        if (totalScore == 0 && activeBuilders > 0) {
            uint256 perBuilder = amountToDistribute / activeBuilders;
            for (uint i = 0; i < builders.length; i++) {
                if (exitInitiatedAt[builders[i]] == 0) {
                    pendingClaims[builders[i]] += perBuilder;
                }
            }
        } else if (totalScore > 0) {
            // Distribute proportionally based on votes
            for (uint i = 0; i < builders.length; i++) {
                if (exitInitiatedAt[builders[i]] == 0) {
                    uint256 share = (amountToDistribute * scores[i]) / totalScore;
                    pendingClaims[builders[i]] += share;
                }
            }
        }
        
        lastDistributionTime = block.timestamp;
        
        emit DistributionExecuted(amountToDistribute, block.timestamp);
    }
    
    function _calculateScore(address builder) internal view returns (uint256) {
        uint256 score = 0;
        
        for (uint i = 0; i < judges.length; i++) {
            Vote storage v = judgeVotes[judges[i]];
            for (uint j = 0; j < v.targets.length; j++) {
                if (v.targets[j] == builder) {
                    score += v.points[j];
                    break;
                }
            }
        }
        
        return score;
    }
    
    function _removeFromArray(address[] storage arr, address item) internal {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == item) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }
    
    // ============ View Functions ============
    
    function getJudges() external view returns (address[] memory) {
        return judges;
    }
    
    function getBuilders() external view returns (address[] memory) {
        return builders;
    }
    
    function getScore(address builder) external view returns (uint256) {
        return _calculateScore(builder);
    }
    
    function getJudgeVote(address judge) external view returns (
        address[] memory targets,
        uint256[] memory points,
        uint256 timestamp
    ) {
        Vote storage v = judgeVotes[judge];
        return (v.targets, v.points, v.timestamp);
    }
    
    function getPendingClaim(address builder) external view returns (uint256) {
        return pendingClaims[builder];
    }
    
    function getTreasuryBalance() external view returns (uint256) {
        // Total USDC minus stakes and pending claims
        uint256 totalStakes = 0;
        uint256 totalPending = 0;
        for (uint i = 0; i < builders.length; i++) {
            totalStakes += builderStake[builders[i]];
            totalPending += pendingClaims[builders[i]];
        }
        return usdc.balanceOf(address(this)) - totalStakes - totalPending;
    }
}
