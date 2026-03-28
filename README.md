# AgentWallieKit

The official iOS SDK for [AgentWallie](https://agentwallie.com) -- server-driven paywalls, A/B experiments, and entitlement management for iOS apps.

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add the package to your `Package.swift` or via Xcode:

```
https://github.com/cynisca/AgentWallieKit
```

Or add it as a dependency:

```swift
dependencies: [
    .package(url: "https://github.com/cynisca/AgentWallieKit", from: "0.5.4")
]
```

## Quick Start

### 1. Configure the SDK

In your `App` init or `AppDelegate`:

```swift
import AgentWallieKit

AgentWallie.configure(apiKey: "pk_your_public_key")
```

### 2. Register a placement

```swift
AgentWallie.shared.register(placement: "app_launch")
```

### 3. Present a paywall

```swift
AgentWallie.shared.presentPaywall(for: "feature_gate")
```

## Features

- **Server-driven paywalls** -- design and update paywalls without app releases
- **A/B experiments** -- run paywall experiments with automatic variant assignment
- **Audience targeting** -- show different paywalls based on user attributes and device info
- **StoreKit 2 integration** -- built-in purchase handling and receipt validation
- **Entitlement management** -- track subscriptions and entitlements automatically
- **Debug overlay** -- shake to inspect placements, events, and config (debug builds)

## Documentation

Full documentation is available at [agentwallie.com/docs/sdk](https://agentwallie.com/docs/sdk).

## License

See [LICENSE](LICENSE) for details.
