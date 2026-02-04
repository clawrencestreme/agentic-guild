// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AgenticGuildStreaming
 * @notice Streaming-funded builders guild where curated judges evaluate builders
 * @dev Simulates continuous distribution via claimable accrued rewards
 * 
 * Key Features:
 * - Curated judges (admin-added) vote on builders
 * - USDC streams proportionally based on vote weights
 * - Builders stake to join, receive streaming rewards
 * - Rewards accrue per-second and are claimable anytime
 */
contract AgenticGuildStreaming is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Constants ============
    uint256 public constant STAKE_AMOUNT = 100e6; // 100 USDC (6 decimals)
    uint256 public constant VOTE_POINTS = 100;    // Each judge has 100 points to distribute
    uint256 public constant EXIT_COOLDOWN = 7 days;
    uint256 public constant PRECISION = 1e18;

    // ============ State ============
    IERC20 public immutable usdc;
    
    // Streaming state
    uint256 public flowRatePerSecond;  // USDC per second to distribute (6 decimals)
    uint256 public lastDistributionTime;
    uint256 public totalScore;
    
    // Judges (curated, can vote)
    mapping(address => bool) public isJudge;
    address[] public judges;
    
    // Builders
    mapping(address => bool) public isBuilder;
    mapping(address => uint256) public builderStake;
    mapping(address => uint256) public exitInitiatedAt;
    mapping(address => uint256) public builderScore;
    mapping(address => uint256) public accruedRewards;
    mapping(address => uint256) public lastClaimTime;
    address[] public builders;
    
    // Voting
    struct Vote {
        address[] targets;
        uint256[] points;
    }
    mapping(address => Vote) internal judgeVotes;

    // ============ Events ============
    event JudgeAdded(address indexed judge);
    event JudgeRemoved(address indexed judge);
    event BuilderJoined(address indexed builder, uint256 stake);
    event BuilderExitInitiated(address indexed builder, uint256 exitTime);
    event BuilderExited(address indexed builder, uint256 stakeReturned);
    event VoteCast(address indexed judge, address[] targets, uint256[] points);
    event FlowRateUpdated(uint256 newRate);
    event TreasuryFunded(address indexed funder, uint256 amount);
    event RewardsClaimed(address indexed builder, uint256 amount);
    event RewardsAccrued(uint256 timestamp, uint256 totalDistributed);

    // ============ Constructor ============
    constructor(address _usdc) Ownable(msg.sender) {
        usdc = IERC20(_usdc);
        lastDistributionTime = block.timestamp;
    }

    // ============ Admin Functions ============
    
    function addJudge(address judge) external onlyOwner {
        require(!isJudge[judge], "Already a judge");
        require(!isBuilder[judge], "Cannot be both judge and builder");
        isJudge[judge] = true;
        judges.push(judge);
        emit JudgeAdded(judge);
    }
    
    function removeJudge(address judge) external onlyOwner {
        require(isJudge[judge], "Not a judge");
        isJudge[judge] = false;
        for (uint i = 0; i < judges.length; i++) {
            if (judges[i] == judge) {
                judges[i] = judges[judges.length - 1];
                judges.pop();
                break;
            }
        }
        delete judgeVotes[judge];
        _updateScores();
        emit JudgeRemoved(judge);
    }
    
    /**
     * @notice Set the streaming flow rate
     * @param _flowRate USDC per second (6 decimals)
     */
    function setFlowRate(uint256 _flowRate) external onlyOwner {
        _accrueRewards();
        flowRatePerSecond = _flowRate;
        emit FlowRateUpdated(_flowRate);
    }
    
    function fund(uint256 amount) external nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
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
        lastClaimTime[msg.sender] = block.timestamp;
        
        emit BuilderJoined(msg.sender, STAKE_AMOUNT);
    }
    
    function initiateExit() external {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] == 0, "Exit already initiated");
        
        _accrueRewards();
        exitInitiatedAt[msg.sender] = block.timestamp;
        
        // Zero out their score
        totalScore -= builderScore[msg.sender];
        builderScore[msg.sender] = 0;
        
        emit BuilderExitInitiated(msg.sender, block.timestamp + EXIT_COOLDOWN);
    }
    
    function completeExit() external nonReentrant {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] != 0, "Exit not initiated");
        require(block.timestamp >= exitInitiatedAt[msg.sender] + EXIT_COOLDOWN, "Cooldown not complete");
        
        // Claim any pending rewards first
        _claimRewards(msg.sender);
        
        uint256 stake = builderStake[msg.sender];
        
        isBuilder[msg.sender] = false;
        builderStake[msg.sender] = 0;
        exitInitiatedAt[msg.sender] = 0;
        
        for (uint i = 0; i < builders.length; i++) {
            if (builders[i] == msg.sender) {
                builders[i] = builders[builders.length - 1];
                builders.pop();
                break;
            }
        }
        
        usdc.safeTransfer(msg.sender, stake);
        emit BuilderExited(msg.sender, stake);
    }
    
    function claimRewards() external nonReentrant {
        require(isBuilder[msg.sender], "Not a builder");
        _accrueRewards();
        _claimRewards(msg.sender);
    }

    // ============ Judge Functions ============
    
    function vote(address[] calldata targets, uint256[] calldata points) external {
        require(isJudge[msg.sender], "Not a judge");
        require(targets.length == points.length, "Length mismatch");
        require(targets.length > 0, "Must vote for at least one builder");
        
        uint256 totalPoints = 0;
        for (uint i = 0; i < points.length; i++) {
            require(isBuilder[targets[i]], "Target is not a builder");
            require(exitInitiatedAt[targets[i]] == 0, "Builder is exiting");
            totalPoints += points[i];
        }
        require(totalPoints == VOTE_POINTS, "Points must sum to 100");
        
        // Check for duplicates
        for (uint i = 0; i < targets.length; i++) {
            for (uint j = i + 1; j < targets.length; j++) {
                require(targets[i] != targets[j], "Duplicate target");
            }
        }
        
        // Accrue rewards before changing scores
        _accrueRewards();
        
        judgeVotes[msg.sender] = Vote({targets: targets, points: points});
        _updateScores();
        
        emit VoteCast(msg.sender, targets, points);
    }

    // ============ Internal Functions ============
    
    function _accrueRewards() internal {
        if (totalScore == 0 || flowRatePerSecond == 0) {
            lastDistributionTime = block.timestamp;
            return;
        }
        
        uint256 elapsed = block.timestamp - lastDistributionTime;
        if (elapsed == 0) return;
        
        uint256 totalToDistribute = elapsed * flowRatePerSecond;
        uint256 treasuryBalance = _getTreasuryBalance();
        
        // Cap at treasury balance
        if (totalToDistribute > treasuryBalance) {
            totalToDistribute = treasuryBalance;
        }
        
        if (totalToDistribute == 0) {
            lastDistributionTime = block.timestamp;
            return;
        }
        
        // Distribute proportionally based on scores
        for (uint i = 0; i < builders.length; i++) {
            address builder = builders[i];
            if (builderScore[builder] > 0 && exitInitiatedAt[builder] == 0) {
                uint256 share = (totalToDistribute * builderScore[builder]) / totalScore;
                accruedRewards[builder] += share;
            }
        }
        
        lastDistributionTime = block.timestamp;
        emit RewardsAccrued(block.timestamp, totalToDistribute);
    }
    
    function _claimRewards(address builder) internal {
        uint256 rewards = accruedRewards[builder];
        if (rewards == 0) return;
        
        accruedRewards[builder] = 0;
        lastClaimTime[builder] = block.timestamp;
        usdc.safeTransfer(builder, rewards);
        
        emit RewardsClaimed(builder, rewards);
    }
    
    function _updateScores() internal {
        // Reset all scores
        totalScore = 0;
        for (uint i = 0; i < builders.length; i++) {
            builderScore[builders[i]] = 0;
        }
        
        // Calculate new scores from all judges
        for (uint i = 0; i < judges.length; i++) {
            Vote storage v = judgeVotes[judges[i]];
            for (uint j = 0; j < v.targets.length; j++) {
                address builder = v.targets[j];
                if (isBuilder[builder] && exitInitiatedAt[builder] == 0) {
                    builderScore[builder] += v.points[j];
                    totalScore += v.points[j];
                }
            }
        }
    }
    
    function _getTreasuryBalance() internal view returns (uint256) {
        uint256 balance = usdc.balanceOf(address(this));
        // Subtract staked amounts
        uint256 totalStaked = 0;
        for (uint i = 0; i < builders.length; i++) {
            totalStaked += builderStake[builders[i]];
        }
        // Subtract accrued but unclaimed rewards
        uint256 totalAccrued = 0;
        for (uint i = 0; i < builders.length; i++) {
            totalAccrued += accruedRewards[builders[i]];
        }
        
        if (balance > totalStaked + totalAccrued) {
            return balance - totalStaked - totalAccrued;
        }
        return 0;
    }

    // ============ View Functions ============
    
    function getJudges() external view returns (address[] memory) { return judges; }
    function getBuilders() external view returns (address[] memory) { return builders; }
    function getJudgeCount() external view returns (uint256) { return judges.length; }
    function getBuilderCount() external view returns (uint256) { return builders.length; }
    function getScore(address builder) external view returns (uint256) { return builderScore[builder]; }
    function getTotalScore() external view returns (uint256) { return totalScore; }
    
    function getJudgeVote(address judge) external view returns (address[] memory targets, uint256[] memory points) {
        Vote storage v = judgeVotes[judge];
        return (v.targets, v.points);
    }
    
    function getPendingRewards(address builder) external view returns (uint256) {
        if (totalScore == 0 || flowRatePerSecond == 0 || builderScore[builder] == 0) {
            return accruedRewards[builder];
        }
        
        uint256 elapsed = block.timestamp - lastDistributionTime;
        uint256 totalToDistribute = elapsed * flowRatePerSecond;
        uint256 treasuryBalance = _getTreasuryBalance();
        if (totalToDistribute > treasuryBalance) totalToDistribute = treasuryBalance;
        
        uint256 pendingShare = (totalToDistribute * builderScore[builder]) / totalScore;
        return accruedRewards[builder] + pendingShare;
    }
    
    function getTreasuryBalance() external view returns (uint256) {
        return _getTreasuryBalance();
    }
    
    function getFlowRatePerSecond() external view returns (uint256) {
        return flowRatePerSecond;
    }
    
    /**
     * @notice Get streaming rate for a specific builder (USDC per second)
     */
    function getBuilderFlowRate(address builder) external view returns (uint256) {
        if (totalScore == 0 || builderScore[builder] == 0) return 0;
        return (flowRatePerSecond * builderScore[builder]) / totalScore;
    }
}
