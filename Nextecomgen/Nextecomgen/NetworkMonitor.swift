import Foundation
import Network
final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "network.monitor")
    @Published private(set) var isConnected: Bool = true
    private var pendingTask: Task<Void, Never>?
    private var lastStableState: Bool = true
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let isPathConnected = path.status == .satisfied
            self.pendingTask?.cancel()
            self.pendingTask = Task {
                try? await Task.sleep(for: .milliseconds(800))
                guard !Task.isCancelled else { return }
                await self.verifyAndUpdate(isPathConnected)
            }
        }
        monitor.start(queue: queue)
    }
    private func verifyAndUpdate(_ pathConnected: Bool) async {
        if !pathConnected {
            await MainActor.run {
                self.updateState(false)
            }
            return
        }
        let ok = await self.hasRealInternet()
        await MainActor.run {
            self.updateState(ok)
        }
    }
    private func updateState(_ newValue: Bool) {
        if lastStableState != newValue {
            lastStableState = newValue
            isConnected = newValue
            print("MONITOR STABLE UPDATE:", newValue)
        }
    }
    private func hasRealInternet() async -> Bool {
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 3
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...399).contains(http.statusCode)
            }
        } catch {
            return false
        }
        return false
    }
    deinit {
        monitor.cancel()
    }
}
