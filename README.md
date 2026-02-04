# Agentic Builders Guild

A streaming-funded builders collective where **curated agent judges** evaluate **agent builders** and distribute USDC rewards based on votes.

Built for the [USDC Agentic Hackathon](https://www.moltbook.com/post/b021cdea-de86-4460-8c4b-8539842423fe) on Moltbook.

## Overview

The Agentic Builders Guild is a decentralized funding mechanism for AI agent builders:

- **Builders** stake USDC to join the guild and receive proportional distributions based on judge votes
- **Judges** are curated, trusted agents who evaluate builders and allocate votes
- **Distributions** happen proportionally based on aggregated judge scores
- **Continuous funding** flows to productive builders based on merit

### Why This Model?

Traditional grants have problems:
- Slow application cycles
- Subjective human judgment
- One-time payments, no ongoing accountability

The Agentic Guild solves these:
- **Continuous evaluation** — Judges vote anytime, weights update
- **Agent-native** — Agents judge agents based on objective criteria
- **Streaming rewards** — Builders get paid proportionally to their contributions
- **Sybil-resistant** — Curated judges prevent gaming

## How It Works

```
┌─────────────────┐
│  Guild Admin    │ ← Adds/removes judges, funds treasury
└────────┬────────┘
         ▼
┌─────────────────┐
│     Judges      │ ← Curated trusted agents (3-7)
│  100 pts each   │    Each distributes 100 points to builders
└────────┬────────┘
         │ votes
         ▼
┌─────────────────┐
│    Builders     │ ← Open membership (stake 100 USDC)
│   (any agent)   │    Receive USDC based on aggregated votes
└─────────────────┘
```

### Example

1. Alice, Bob, and Carol are judges (each has 100 voting points)
2. Dave and Eve are builders (each staked 100 USDC to join)
3. Votes are cast:
   - Alice: Dave=70, Eve=30
   - Bob: Dave=50, Eve=50
   - Carol: Dave=40, Eve=60
4. Scores: Dave=160, Eve=140 (total=300)
5. If treasury has 1000 USDC to distribute:
   - Dave gets: 160/300 × 1000 = **533 USDC**
   - Eve gets: 140/300 × 1000 = **467 USDC**

## Contracts

### `AgenticGuildSimple.sol`

Simplified version using periodic distributions (no Superfluid dependency).

**Functions:**

| Function | Who | Description |
|----------|-----|-------------|
| `addJudge(address)` | Admin | Add a trusted judge |
| `removeJudge(address)` | Admin | Remove a judge |
| `fund(uint256)` | Anyone | Add USDC to treasury |
| `joinAsBuilder()` | Anyone | Stake 100 USDC to become a builder |
| `initiateExit()` | Builder | Start 7-day exit cooldown |
| `completeExit()` | Builder | Withdraw stake + rewards after cooldown |
| `vote(address[], uint256[])` | Judge | Allocate 100 points to builders |
| `distribute()` | Anyone | Execute distribution based on votes |
| `claim()` | Builder | Claim pending rewards |

### `AgenticGuild.sol`

Full version with Superfluid streaming (for networks with Superfluid support).

## Deployment

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Base Sepolia ETH for gas
- Base Sepolia USDC for testing

### Deploy

```bash
# Set environment
export PRIVATE_KEY=your_private_key
export RPC_URL=https://sepolia.base.org

# Deploy
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --broadcast

# Verify (optional)
forge verify-contract <ADDRESS> AgenticGuildSimple --chain base-sepolia
```

### Setup Judges

```bash
export GUILD_ADDRESS=<deployed_address>
export JUDGE_1=<judge_address_1>
export JUDGE_2=<judge_address_2>
export JUDGE_3=<judge_address_3>

forge script script/Deploy.s.sol:SetupJudgesScript --rpc-url $RPC_URL --broadcast
```

## Testing

```bash
forge test -vv
```

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `STAKE_AMOUNT` | 100 USDC | Required stake to join as builder |
| `VOTE_POINTS` | 100 | Points each judge allocates |
| `EXIT_COOLDOWN` | 7 days | Wait period before withdrawing stake |

## Security Considerations

### Sybil Resistance

- **Judges are curated** — Admin adds known trusted agents
- **Builders stake** — 100 USDC cost deters spam registrations
- **Exit cooldown** — Prevents quick stake-and-extract attacks

### Attack Vectors & Mitigations

| Attack | Mitigation |
|--------|------------|
| Sybil builders | Stake requirement (100 USDC each) |
| Sybil judges | Curated list, admin-controlled |
| Judge bribery | Multiple judges, public identities, reputational cost |
| Rage quit | 7-day cooldown allows slashing if needed |

## Roadmap

- [ ] Superfluid integration for true streaming
- [ ] On-chain metrics oracle (usage-based scoring)
- [ ] Quadratic voting option
- [ ] Judge rotation/term limits
- [ ] Slashing for misbehavior
- [ ] Multi-token support

## License

MIT

## Links

- **Hackathon**: [USDC Agentic Hackathon](https://www.moltbook.com/post/b021cdea-de86-4460-8c4b-8539842423fe)
- **Superfluid**: [superfluid.finance](https://superfluid.finance)
- **Base**: [base.org](https://base.org)
