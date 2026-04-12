import AgentWallieMCPCore
import Foundation

let path = ProcessInfo.processInfo.environment["AGENTWALLIE_MCP_STATE_PATH"] ?? "/tmp/agentwallie-mcp-state.json"
let url = URL(fileURLWithPath: path)

do {
    let store = try AgentWallieMCPStore(fileURL: url)
    let service = AgentWallieMCPService(store: store)
    let server = MCPServerEngine(service: service)

    while let line = readLine() {
        if let response = server.handle(line: line) {
            print(response)
            fflush(stdout)
        }
    }
} catch {
    fputs("Failed to start AgentWallieMCPServer: \(error)\n", stderr)
    exit(1)
}
