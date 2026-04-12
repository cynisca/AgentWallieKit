import Foundation

public final class MCPServerEngine: @unchecked Sendable {
    private let service: AgentWallieMCPService
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(service: AgentWallieMCPService) {
        self.service = service
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    public func handle(line: String) -> String? {
        guard let data = line.data(using: .utf8),
              let request = try? decoder.decode(JSONRPCRequest.self, from: data) else {
            return nil
        }

        let response: JSONRPCResponse
        do {
            switch request.method {
            case "initialize":
                response = .success(id: request.id, result: .object([
                    "protocolVersion": .string("2024-11-05"),
                    "serverInfo": .object([
                        "name": .string("AgentWallieMCPServer"),
                        "version": .string("0.1.0"),
                    ]),
                    "capabilities": .object([
                        "tools": .object([:]),
                    ]),
                ]))
            case "tools/list":
                response = .success(id: request.id, result: .object([
                    "tools": encode(service.toolDefinitions()),
                ]))
            case "tools/call":
                guard let params = request.params?.objectValue,
                      let name = params["name"]?.stringValue else {
                    throw MCPError.invalidParams("tools/call requires a tool name")
                }
                let arguments = params["arguments"]?.objectValue ?? [:]
                let result = try service.callTool(name: name, arguments: arguments)
                response = .success(id: request.id, result: .object([
                    "content": .array([
                        .object([
                            "type": .string("text"),
                            "text": .string(stringify(result)),
                        ]),
                    ]),
                    "structuredContent": result,
                    "isError": .bool(false),
                ]))
            default:
                throw MCPError.notFound("Unknown method '\(request.method)'")
            }
        } catch {
            response = .failure(id: request.id, code: -32000, message: error.localizedDescription)
        }

        let responseData = try! encoder.encode(response)
        return String(data: responseData, encoding: .utf8)
    }

    private func encode<T: Encodable>(_ value: T) -> JSONValue {
        let data = try! JSONEncoder().encode(value)
        let object = try! JSONSerialization.jsonObject(with: data)
        return JSONValue.fromAny(object)
    }

    private func stringify(_ value: JSONValue) -> String {
        let object = value.toAny()
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "\(value)"
        }
        return string
    }
}

public struct JSONRPCRequest: Codable, Sendable {
    public var jsonrpc: String
    public var id: JSONValue?
    public var method: String
    public var params: JSONValue?

    public init(jsonrpc: String = "2.0", id: JSONValue?, method: String, params: JSONValue? = nil) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponse: Codable, Sendable {
    public var jsonrpc: String
    public var id: JSONValue?
    public var result: JSONValue?
    public var error: JSONRPCError?

    public init(jsonrpc: String = "2.0", id: JSONValue?, result: JSONValue?, error: JSONRPCError?) {
        self.jsonrpc = jsonrpc
        self.id = id
        self.result = result
        self.error = error
    }

    public static func success(id: JSONValue?, result: JSONValue) -> JSONRPCResponse {
        JSONRPCResponse(jsonrpc: "2.0", id: id, result: result, error: nil)
    }

    public static func failure(id: JSONValue?, code: Int, message: String) -> JSONRPCResponse {
        JSONRPCResponse(jsonrpc: "2.0", id: id, result: nil, error: JSONRPCError(code: code, message: message))
    }
}

public struct JSONRPCError: Codable, Sendable {
    public var code: Int
    public var message: String

    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}
