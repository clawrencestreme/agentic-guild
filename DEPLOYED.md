# Deployed Contracts - Base Sepolia

## AgenticGuildStreaming (Main - With Real-Time Streaming)

| Contract | Address |
|----------|---------|
| MockUSDC | `0x3790f29015609f7aC2d323914EE8d9E062a59bC3` |
| AgenticGuildStreaming | `0x82B190bD47146991F1917c266b600Dd18b6D74F7` |

### Active Demo State
- **Treasury:** 100,000 USDC
- **Flow Rate:** 1 USDC/second (~86,400 USDC/day)
- **Registered Builders:** 3
  - Builder 1: `0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A` (50 points)
  - Builder 2: `0x1563915e194D8CfBA1943570603F7606A3115508` (30 points)
  - Builder 3: `0x5CbDd86a2FA8Dc4bDdd8a8f69dBa48572EeC07FB` (20 points)
- **Judge:** `0xD1B8fa09E45a403885F3970DAB026A6a33fA7ebC`

### How Streaming Works
1. Admin sets a flow rate (USDC per second)
2. Judges vote to assign point weights to builders
3. USDC streams proportionally based on vote weights
4. Builders can claim accrued rewards anytime

---

## AgenticGuildSimple (Batch Distribution Version)

| Contract | Address |
|----------|---------|
| MockUSDC | `0x6c9C433b3471C5a5f6084Fa2185DAB8A43372CEd` |
| AgenticGuildSimple | `0x1957773C8Ce9618f3E822b91bc359B55Da55A7Cc` |

*Original batch distribution model - rewards distributed periodically rather than streamed.*

---

## Network Info
- **Network:** Base Sepolia
- **Chain ID:** 84532
- **RPC:** https://sepolia.base.org
- **Explorer:** https://sepolia.basescan.org

## View on Explorer
- [AgenticGuildStreaming](https://sepolia.basescan.org/address/0x82B190bD47146991F1917c266b600Dd18b6D74F7)
- [MockUSDC](https://sepolia.basescan.org/address/0x3790f29015609f7aC2d323914EE8d9E062a59bC3)
