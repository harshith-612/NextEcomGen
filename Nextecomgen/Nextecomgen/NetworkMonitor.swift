import Foundation
import Network
@MainActor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "NetworkMonitorQueue"
    )
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            print(
                "NWPath:",
                path.status == .satisfied
                ? "satisfied"
                : "unsatisfied"
            )
            Task {
                let internetAvailable =
                await self.verifyInternet()
                await MainActor.run {
                    print(
                        "REAL INTERNET:",
                        internetAvailable
                    )
                    if self.isConnected != internetAvailable {
                        print(
                            "NETWORK UPDATE:",
                            internetAvailable
                        )
                        self.isConnected =
                        internetAvailable
                    }
                }
            }
        }
        monitor.start(
            queue: queue
        )
    }
    private func verifyInternet() async -> Bool {
        guard let url = URL(
            string:
            "https://www.apple.com/library/test/success.html"
        ) else {
            return false
        }
        var request =
        URLRequest(
            url: url
        )
        request.httpMethod = "GET"

        request.timeoutInterval = 5
        do {

            let (_, response) =
            try await URLSession.shared.data(
                for: request
            )
            if let http =
                response as? HTTPURLResponse {
                print(
                    "STATUS:",
                    http.statusCode
                )
                return http.statusCode == 200
            }
        } catch {
            print(
                "Internet check failed:",
                error.localizedDescription
            )
        }
        return false
    }
    deinit {
        monitor.cancel()
    }
}
