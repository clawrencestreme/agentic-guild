# Deployed Contracts - Base Sepolia

## AgenticGuild with Superfluid GDA (LIVE STREAMING)

| Contract | Address |
|----------|---------|
| **AgenticGuild** | [`0x8d70f3872bf88d4AEF352999A672D0786A673030`](https://sepolia.basescan.org/address/0x8d70f3872bf88d4AEF352999A672D0786A673030) |
| GDA Pool | [`0x1E7206AfE8996fFB452c0b297485fc1DDc21b0ab`](https://sepolia.basescan.org/address/0x1E7206AfE8996fFB452c0b297485fc1DDc21b0ab) |
| fUSDC | [`0x6B0dacea6a72E759243c99Eaed840DEe9564C194`](https://sepolia.basescan.org/address/0x6B0dacea6a72E759243c99Eaed840DEe9564C194) |
| fUSDCx | [`0x1650581F573eAd727B92073B5Ef8B4f5B94D1648`](https://sepolia.basescan.org/address/0x1650581F573eAd727B92073B5Ef8B4f5B94D1648) |

### Active Demo State
- **Treasury:** 50,000 fUSDCx
- **Flow Rate:** 0.01 fUSDCx/second (~864 fUSDC/day)
- **Active Builder:** `0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A` (100 units, receiving full stream)
- **Judge:** `0xD1B8fa09E45a403885F3970DAB026A6a33fA7ebC`

### How It Works
1. Admin sets flow rate via `setFlowRate(int96)`
2. Judges vote to assign point weights to builders via `vote(address[], uint256[])`
3. Builders connect to the GDA pool to receive real-time streaming rewards
4. Balance updates EVERY SECOND via Superfluid's streaming infrastructure
5. No claiming required — funds flow directly to wallet in real-time

### Verified Streaming
```
Builder balance at T+0s:  0.12 fUSDCx
Builder balance at T+3s:  0.16 fUSDCx  (+0.04)
Builder balance at T+6s:  0.20 fUSDCx  (+0.04)
```
Flow rate confirmed: ~0.01 fUSDCx/second

---

## Superfluid Infrastructure (Base Sepolia)

| Contract | Address |
|----------|---------|
| Superfluid Host | `0x109412E3C84f0539b43d39dB691B08c90f58dC7c` |
| GDA | `0x53F4f44C813Dc380182d0b2b67fe5832A12B97f8` |
| GDA Forwarder | `0x6DA13Bde224A05a288748d857b9e7DDEffd1dE08` |

---

## Network Info
- **Network:** Base Sepolia
- **Chain ID:** 84532
- **RPC:** https://sepolia.base.org
- **Explorer:** https://sepolia.basescan.org
