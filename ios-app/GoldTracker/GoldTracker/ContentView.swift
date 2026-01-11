import SwiftUI

struct ContentView: View {
    @StateObject private var wsManager = WebSocketManager()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Connection Status
                HStack {
                    Circle()
                        .fill(wsManager.isConnected ? .green : .red)
                        .frame(width: 12, height: 12)
                    Text(wsManager.isConnected ? "Connecté" : "Déconnecté")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Gold Display
                VStack(spacing: 10) {
                    Text("OR")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text(formatGold(wsManager.gold))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.5), radius: 10)
                }

                // Last Update
                if let lastUpdate = wsManager.lastUpdate {
                    Text("Mis à jour: \(formatTime(lastUpdate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Error Message
                if let error = wsManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Connect/Disconnect Button
                Button(action: {
                    if wsManager.isConnected {
                        wsManager.disconnect()
                    } else {
                        wsManager.connect()
                    }
                }) {
                    HStack {
                        Image(systemName: wsManager.isConnected ? "wifi.slash" : "wifi")
                        Text(wsManager.isConnected ? "Déconnecter" : "Connecter")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(wsManager.isConnected ? Color.red : Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Gold Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(wsManager: wsManager)
            }
        }
    }

    private func formatGold(_ gold: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        return formatter.string(from: NSNumber(value: gold)) ?? "\(gold)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

struct SettingsView: View {
    @ObservedObject var wsManager: WebSocketManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Configuration Serveur") {
                    TextField("URL WebSocket", text: $wsManager.serverURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Text("Exemples:\n• Local: ws://192.168.1.XX:3001\n• Tailscale: ws://100.XX.XX.XX:3001")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Appliquer et Reconnecter") {
                        wsManager.disconnect()
                        wsManager.connect()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
