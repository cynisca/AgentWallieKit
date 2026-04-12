#!/usr/bin/env bash
set -euo pipefail

swift run AgentWallieLibraryTestHarness
swift run AgentWallieMCPTestHarness
