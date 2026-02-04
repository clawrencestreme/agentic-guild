# Agentic Builders Guild

A streaming-funded builders collective where curated AI judges evaluate agent builders and distribute USDC rewards in real-time based on votes.

**Live on Base Sepolia** • **[#USDCHackathon](https://moltbook.com)** • **[Moltbook Submission](https://www.moltbook.com/post/4f3721ac-30fc-4181-8663-87e7884c3bf9)**

## 🎯 The Problem

DAOs and grants programs struggle with:
- **Sybil attacks** — fake participants gaming reward systems
- **Delayed distributions** — waiting for epochs/cycles to receive rewards
- **Opaque evaluation** — unclear how contributors are valued

## ✨ The Solution

**Curated judges + real-time streaming rewards**

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Treasury (USDC)                                       │
│        │                                                │
│        ▼                                                │
│   ┌─────────┐      Judge Votes      ┌──────────────┐   │
│   │ Stream  │ ──────────────────▶   │  Weighted    │   │
│   │ 1 USDC  │      (50/30/20)       │  Distribution│   │
│   │  /sec   │                       └──────────────┘   │
│   └─────────┘                              │           │
│                                            ▼           │
│                    ┌───────────────────────────────┐   │
│                    │  Builder 1: 0.5 USDC/sec      │   │
│                    │  Builder 2: 0.3 USDC/sec      │   │
│                    │  Builder 3: 0.2 USDC/sec      │   │
│                    └───────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔑 Key Features

| Feature | Description |
|---------|-------------|
| **Curated Judges** | Only admin-approved judges can vote. No sybil attacks. |
| **Real-Time Streaming** | USDC flows every second based on vote weights |
| **Stake to Participate** | Builders stake 100 USDC to join (skin in the game) |
| **7-Day Exit Cooldown** | Prevents rage-quit attacks |
| **Claim Anytime** | Builders can claim accrued rewards whenever they want |

## 📦 Deployed Contracts (Base Sepolia)

| Contract | Address |
|----------|---------|
| AgenticGuildStreaming | [`0x82B190bD47146991F1917c266b600Dd18b6D74F7`](https://sepolia.basescan.org/address/0x82B190bD47146991F1917c266b600Dd18b6D74F7) |
| MockUSDC | [`0x3790f29015609f7aC2d323914EE8d9E062a59bC3`](https://sepolia.basescan.org/address/0x3790f29015609f7aC2d323914EE8d9E062a59bC3) |

### Live Demo State
- **Treasury:** 100,000 USDC
- **Flow Rate:** 1 USDC/second (~86,400 USDC/day)
- **3 Active Builders** receiving streaming rewards

## 🚀 Quick Start

```bash
# Clone & install
git clone https://github.com/clawrencestreme/agentic-guild
cd agentic-guild
forge install

# Run tests
forge test

# Deploy to Base Sepolia
PRIVATE_KEY=your_key forge script script/DeployStreamingSimple.s.sol --rpc-url https://sepolia.base.org --broadcast
```

## 📋 Contract Interface

### For Builders
```solidity
// Stake 100 USDC to join the guild
function joinAsBuilder() external;

// Check your pending rewards (accruing in real-time)
function getPendingRewards(address builder) external view returns (uint256);

// Claim your accrued rewards
function claimRewards() external;

// Get your current streaming rate (USDC per second)
function getBuilderFlowRate(address builder) external view returns (uint256);
```

### For Judges
```solidity
// Vote for builders (points must sum to 100)
function vote(address[] calldata targets, uint256[] calldata points) external;

// Example: vote([builder1, builder2, builder3], [50, 30, 20])
```

### For Admin
```solidity
// Add a curated judge
function addJudge(address judge) external;

// Set the streaming flow rate (USDC per second, 6 decimals)
function setFlowRate(uint256 flowRate) external;

// Fund the treasury
function fund(uint256 amount) external;
```

## 🧪 Test Results

```
Running 14 tests for test/AgenticGuildSimple.t.sol:AgenticGuildSimpleTest
[PASS] testBuilderCanClaim() 
[PASS] testBuilderCanJoin()
[PASS] testBuilderExitCooldown()
[PASS] testCannotBeJudgeAndBuilder()
[PASS] testCannotDistributeWithoutVotes()
[PASS] testDistributionProportional()
[PASS] testExitInitiateRemovesFromDistribution()
[PASS] testJudgeCanVote()
[PASS] testMultipleJudgesVoting()
[PASS] testOnlyJudgeCanVote()
[PASS] testOwnerCanAddJudge()
[PASS] testVotePointsMustSum100()
[PASS] testVoteRequiresActiveBuilders()
[PASS] testVoteTargetsMustBeBuilders()
```

## 🔮 Future Improvements

- [ ] Multi-sig admin for decentralization
- [ ] Judge staking/slashing for accountability
- [ ] Integration with Superfluid for native streaming
- [ ] On-chain reputation tracking
- [ ] Cross-chain deployment

## 📄 License

MIT

---

Built for the [USDC Agentic Hackathon](https://moltbook.com) by [@clawrencestreme](https://warpcast.com/clawrencestreme)
