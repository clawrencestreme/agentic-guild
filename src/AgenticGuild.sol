// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISuperfluid.sol";

/**
 * @title AgenticGuild
 * @notice A streaming-funded builders guild where curated judges evaluate builders
 * @dev Uses Superfluid GDA for continuous USDC distribution based on voting
 * 
 * Roles:
 * - Admin: Manages judges, sets flow rate, funds treasury
 * - Judges: Curated agents who vote on builders (cannot receive distributions)
 * - Builders: Stake to join, receive streaming USDC based on judge votes
 */
contract AgenticGuild is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ============ Constants ============
    uint256 public constant STAKE_AMOUNT = 100e6; // 100 USDC (6 decimals)
    uint256 public constant VOTE_POINTS = 100;    // Each judge has 100 points to distribute
    uint256 public constant MIN_UNITS = 100;      // Minimum units for any builder
    uint256 public constant EXIT_COOLDOWN = 7 days;

    // ============ State ============
    
    // Token references
    IERC20 public immutable usdc;
    ISuperToken public immutable usdcx;
    
    // Superfluid references
    ISuperfluid public immutable superfluid;
    IGeneralDistributionAgreementV1 public immutable gda;
    ISuperfluidPool public pool;
    
    // Judges (curated, can vote)
    mapping(address => bool) public isJudge;
    address[] public judges;
    
    // Builders (stake to join, receive distributions)
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
    mapping(address => Vote) public judgeVotes; // judge => their current vote allocation
    
    // Flow rate
    int96 public flowRate;

    // ============ Events ============
    
    event JudgeAdded(address indexed judge);
    event JudgeRemoved(address indexed judge);
    event BuilderJoined(address indexed builder, uint256 stake);
    event BuilderExitInitiated(address indexed builder, uint256 exitTime);
    event BuilderExited(address indexed builder, uint256 stakeReturned);
    event VoteCast(address indexed judge, address[] targets, uint256[] points);
    event WeightsSynced(uint256 timestamp, uint256 totalUnits);
    event FlowRateUpdated(int96 newRate);
    event TreasuryFunded(address indexed funder, uint256 amount);

    // ============ Constructor ============
    
    constructor(
        address _usdc,
        address _usdcx,
        address _superfluid
    ) Ownable(msg.sender) {
        usdc = IERC20(_usdc);
        usdcx = ISuperToken(_usdcx);
        superfluid = ISuperfluid(_superfluid);
        
        // Get GDA agreement
        gda = IGeneralDistributionAgreementV1(
            superfluid.getAgreementClass(GDA_TYPE)
        );
    }
    
    // ============ Admin Functions ============
    
    /**
     * @notice Initialize the Superfluid distribution pool
     * @dev Must be called after deployment before distributions can start
     */
    function initializePool() external onlyOwner {
        require(address(pool) == address(0), "Pool already initialized");
        
        PoolConfig memory config = PoolConfig({
            transferabilityForUnitsOwner: false,
            distributionFromAnyAddress: false
        });
        
        pool = gda.createPool(usdcx, address(this), config);
    }
    
    /**
     * @notice Add a judge (curated, trusted agent)
     */
    function addJudge(address judge) external onlyOwner {
        require(!isJudge[judge], "Already a judge");
        require(!isBuilder[judge], "Cannot be both judge and builder");
        
        isJudge[judge] = true;
        judges.push(judge);
        
        emit JudgeAdded(judge);
    }
    
    /**
     * @notice Remove a judge
     */
    function removeJudge(address judge) external onlyOwner {
        require(isJudge[judge], "Not a judge");
        
        isJudge[judge] = false;
        
        // Remove from array
        for (uint i = 0; i < judges.length; i++) {
            if (judges[i] == judge) {
                judges[i] = judges[judges.length - 1];
                judges.pop();
                break;
            }
        }
        
        // Clear their votes
        delete judgeVotes[judge];
        
        emit JudgeRemoved(judge);
    }
    
    /**
     * @notice Set the distribution flow rate
     * @param _flowRate USDC per second (in wei, so 6 decimals)
     */
    function setFlowRate(int96 _flowRate) external onlyOwner {
        require(address(pool) != address(0), "Pool not initialized");
        require(_flowRate >= 0, "Flow rate must be non-negative");
        
        flowRate = _flowRate;
        
        // Update Superfluid flow
        gda.distributeFlow(usdcx, address(this), pool, _flowRate);
        
        emit FlowRateUpdated(_flowRate);
    }
    
    /**
     * @notice Fund the treasury with USDC
     * @param amount Amount of USDC to deposit (will be wrapped to USDCx)
     */
    function fund(uint256 amount) external nonReentrant {
        usdc.safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve and wrap to USDCx
        usdc.approve(address(usdcx), amount);
        usdcx.upgrade(amount);
        
        emit TreasuryFunded(msg.sender, amount);
    }
    
    // ============ Builder Functions ============
    
    /**
     * @notice Join the guild as a builder by staking USDC
     */
    function joinAsBuilder() external nonReentrant {
        require(!isBuilder[msg.sender], "Already a builder");
        require(!isJudge[msg.sender], "Judges cannot be builders");
        require(address(pool) != address(0), "Pool not initialized");
        
        // Transfer stake
        usdc.safeTransferFrom(msg.sender, address(this), STAKE_AMOUNT);
        
        isBuilder[msg.sender] = true;
        builderStake[msg.sender] = STAKE_AMOUNT;
        builders.push(msg.sender);
        
        // Add to pool with minimum units
        pool.updateMemberUnits(msg.sender, uint128(MIN_UNITS));
        
        emit BuilderJoined(msg.sender, STAKE_AMOUNT);
    }
    
    /**
     * @notice Initiate exit from the guild (starts cooldown)
     */
    function initiateExit() external {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] == 0, "Exit already initiated");
        
        exitInitiatedAt[msg.sender] = block.timestamp;
        
        // Remove from pool
        pool.updateMemberUnits(msg.sender, 0);
        
        emit BuilderExitInitiated(msg.sender, block.timestamp + EXIT_COOLDOWN);
    }
    
    /**
     * @notice Complete exit and withdraw stake after cooldown
     */
    function completeExit() external nonReentrant {
        require(isBuilder[msg.sender], "Not a builder");
        require(exitInitiatedAt[msg.sender] != 0, "Exit not initiated");
        require(
            block.timestamp >= exitInitiatedAt[msg.sender] + EXIT_COOLDOWN,
            "Cooldown not complete"
        );
        
        uint256 stake = builderStake[msg.sender];
        
        // Clean up state
        isBuilder[msg.sender] = false;
        builderStake[msg.sender] = 0;
        exitInitiatedAt[msg.sender] = 0;
        
        // Remove from array
        for (uint i = 0; i < builders.length; i++) {
            if (builders[i] == msg.sender) {
                builders[i] = builders[builders.length - 1];
                builders.pop();
                break;
            }
        }
        
        // Return stake
        usdc.safeTransfer(msg.sender, stake);
        
        emit BuilderExited(msg.sender, stake);
    }
    
    // ============ Judge Functions ============
    
    /**
     * @notice Cast votes for builders
     * @param targets Array of builder addresses to vote for
     * @param points Array of points to allocate (must sum to VOTE_POINTS)
     */
    function vote(address[] calldata targets, uint256[] calldata points) external {
        require(isJudge[msg.sender], "Not a judge");
        require(targets.length == points.length, "Length mismatch");
        require(targets.length > 0, "Must vote for at least one builder");
        
        // Validate total points
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
        
        // Store vote
        judgeVotes[msg.sender] = Vote({
            targets: targets,
            points: points,
            timestamp: block.timestamp
        });
        
        emit VoteCast(msg.sender, targets, points);
    }
    
    // ============ Sync Function ============
    
    /**
     * @notice Sync pool units based on current votes
     * @dev Can be called by anyone (permissionless crank)
     */
    function sync() external {
        require(address(pool) != address(0), "Pool not initialized");
        
        // Calculate scores for each builder
        uint256[] memory scores = new uint256[](builders.length);
        uint256 totalScore = 0;
        
        for (uint i = 0; i < builders.length; i++) {
            address builder = builders[i];
            if (exitInitiatedAt[builder] != 0) continue; // Skip exiting builders
            
            uint256 score = _calculateScore(builder);
            scores[i] = score;
            totalScore += score;
        }
        
        // Update pool units
        for (uint i = 0; i < builders.length; i++) {
            address builder = builders[i];
            
            uint128 units;
            if (exitInitiatedAt[builder] != 0) {
                units = 0;
            } else if (totalScore == 0) {
                units = uint128(MIN_UNITS);
            } else {
                // Scale scores to units (minimum MIN_UNITS)
                units = uint128(scores[i] > MIN_UNITS ? scores[i] : MIN_UNITS);
            }
            
            pool.updateMemberUnits(builder, units);
        }
        
        emit WeightsSynced(block.timestamp, totalScore);
    }
    
    /**
     * @notice Calculate a builder's score from all judge votes
     */
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
    
    // ============ View Functions ============
    
    function getJudges() external view returns (address[] memory) {
        return judges;
    }
    
    function getBuilders() external view returns (address[] memory) {
        return builders;
    }
    
    function getJudgeCount() external view returns (uint256) {
        return judges.length;
    }
    
    function getBuilderCount() external view returns (uint256) {
        return builders.length;
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
    
    function getBuilderUnits(address builder) external view returns (uint128) {
        return pool.getUnits(builder);
    }
    
    function getTotalUnits() external view returns (uint128) {
        return pool.getTotalUnits();
    }
    
    function getTreasuryBalance() external view returns (uint256) {
        return usdcx.balanceOf(address(this));
    }
}
