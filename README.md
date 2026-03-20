# AgentWallieKit

The iOS SDK for [AgentWallie](https://github.com/cynisca/agentwallie) — an agent-first paywall platform.

## Installation

### Swift Package Manager

Add AgentWallieKit to your project in Xcode:

1. **File → Add Package Dependencies**
2. Enter: `https://github.com/cynisca/AgentWallieKit`
3. Select **AgentWallieKit** and add to your target

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/cynisca/AgentWallieKit", from: "0.1.0")
]
```

## Quick Start

```swift
import AgentWallieKit

// 1. Configure (in your App init or AppDelegate)
AgentWallie.configure(
    apiKey: "pk_your_public_key",
    options: AgentWallieOptions(
        networkEnvironment: .custom(URL(string: "https://your-api.run.app")!)
    )
)

// 2. Identify user
AgentWallie.shared.identify(userId: "user_123")
AgentWallie.shared.setUserAttributes(["plan": "free"])

// 3. Show paywalls via placements
AgentWallie.shared.register(placement: "workout_completed") {
    // Runs if user already has entitlement
    showProFeature()
}

// 4. Or present directly
AgentWallie.shared.presentPaywall(id: "paywall_id")
```

## Features

- **Native SwiftUI rendering** — 17 component types rendered natively
- **Campaign evaluation** — placement → campaign → audience → experiment → paywall
- **A/B testing** — deterministic variant assignment with holdout groups
- **Audience targeting** — filter engine with 11 operators and dot-notation paths
- **StoreKit 2** — default purchase handling (or bring your own PurchaseController)
- **Event tracking** — automatic + custom events with batched delivery
- **Config caching** — fetches on launch, auto-refreshes, caches locally

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## Documentation

Full documentation at [github.com/cynisca/agentwallie](https://github.com/cynisca/agentwallie/tree/main/packages/docs).

## License

MIT
