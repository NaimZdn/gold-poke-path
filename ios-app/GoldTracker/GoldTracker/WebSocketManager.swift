import Foundation

struct GoldState: Codable {
    let type: String
    let gold: Int
    let ts: Double
}

@MainActor
class WebSocketManager: ObservableObject {
    @Published var gold: Int = 0
    @Published var lastUpdate: Date?
    @Published var isConnected: Bool = false
    @Published var errorMessage: String?
    @Published var serverURL: String = "ws://100.74.234.38:3001"

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var pingTask: Task<Void, Never>?

    init() {
        // Load saved URL if exists
        if let savedURL = UserDefaults.standard.string(forKey: "serverURL") {
            serverURL = savedURL
        }
    }

    func connect() {
        disconnect()
        errorMessage = nil

        guard let url = URL(string: serverURL) else {
            errorMessage = "URL invalide"
            return
        }

        // Save URL for next launch
        UserDefaults.standard.set(serverURL, forKey: "serverURL")

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        webSocketTask = session?.webSocketTask(with: url)
        webSocketTask?.resume()

        isConnected = true
        receiveMessage()
        startPing()
    }

    func disconnect() {
        pingTask?.cancel()
        pingTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        isConnected = false
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            Task { @MainActor in
                guard let self = self else { return }

                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    // Continue receiving
                    self.receiveMessage()

                case .failure(let error):
                    self.isConnected = false
                    self.errorMessage = "Connexion perdue: \(error.localizedDescription)"
                }
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            let state = try JSONDecoder().decode(GoldState.self, from: data)
            gold = state.gold
            lastUpdate = Date(timeIntervalSince1970: state.ts / 1000)
            errorMessage = nil
        } catch {
            // Silently ignore parse errors for non-state messages
        }
    }

    private func startPing() {
        pingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                webSocketTask?.sendPing { error in
                    if let error = error {
                        Task { @MainActor in
                            self.isConnected = false
                            self.errorMessage = "Ping failed: \(error.localizedDescription)"
                        }
                    }
                }
            }
        }
    }
}
