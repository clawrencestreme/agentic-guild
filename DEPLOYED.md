# Deployed Contracts - Base Sepolia

**Network:** Base Sepolia (Chain ID: 84532)
**Deployed:** 2026-02-04

## Contracts

| Contract | Address |
|----------|---------|
| MockUSDC | `0x6c9C433b3471C5a5f6084Fa2185DAB8A43372CEd` |
| AgenticGuild | `0x1957773C8Ce9618f3E822b91bc359B55Da55A7Cc` |

## Demo Accounts

| Role | Address |
|------|---------|
| Admin/Judge | `0xD1B8fa09E45a403885F3970DAB026A6a33fA7ebC` |
| Builder 1 | `0x5DBba567D3406d1bf204f9e12F53946F780BfD03` |
| Builder 2 | `0xe2D9Be382972502ecc311132c1Cd175Be41144eb` |
| Builder 3 | `0xe9143c47C2C6Ced30eC6f3A1b1C60bc3645E95D4` |

## Demo Transactions

### 1. Deployment
- MockUSDC deployed with 1M test USDC
- AgenticGuild deployed with MockUSDC
- Admin added as judge
- Treasury funded with 10,000 USDC

### 2. Builders Join
- 3 builders staked 100 USDC each
- All received 200 USDC mint + gas ETH

### 3. Voting
Judge voted: Builder1=50%, Builder2=30%, Builder3=20%

### 4. Distribution
- `distribute()` called
- Builder 1: 5,000 USDC pending ✓
- Builder 2: 3,000 USDC pending ✓
- Builder 3: 2,000 USDC pending ✓

### 5. Claiming
- Builder 1 claimed 5,000 USDC ✓

## Block Explorer

- [AgenticGuild on BaseScan](https://sepolia.basescan.org/address/0x1957773C8Ce9618f3E822b91bc359B55Da55A7Cc)
- [MockUSDC on BaseScan](https://sepolia.basescan.org/address/0x6c9C433b3471C5a5f6084Fa2185DAB8A43372CEd)
