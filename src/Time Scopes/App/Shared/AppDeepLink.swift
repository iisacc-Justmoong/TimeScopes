import Combine
import Foundation

enum AppDeepLinkTab: String {
    case home
    case calendar
    case pulse
    case preferences
}

struct AppDeepLink: Equatable, Identifiable {
    static let scheme = "timescopes"
    static let host = "open"

    let id: UUID
    let tab: AppDeepLinkTab
    let section: String?
    let item: String?

    init(
        id: UUID = UUID(),
        tab: AppDeepLinkTab,
        section: String? = nil,
        item: String? = nil
    ) {
        self.id = id
        self.tab = tab
        self.section = section
        self.item = item
    }

    init?(url: URL) {
        guard url.scheme?.lowercased() == Self.scheme else { return nil }
        if let host = url.host, !host.isEmpty, host != Self.host {
            return nil
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let query = components.queryItems ?? []
        guard let tabValue = query.first(where: { $0.name == "tab" })?.value,
              let tab = AppDeepLinkTab(rawValue: tabValue) else {
            return nil
        }

        self.id = UUID()
        self.tab = tab
        self.section = query.first(where: { $0.name == "section" })?.value
        self.item = query.first(where: { $0.name == "item" })?.value
    }

    static func url(
        tab: AppDeepLinkTab,
        section: String? = nil,
        item: String? = nil
    ) -> URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "tab", value: tab.rawValue),
        ]
        if let section, !section.isEmpty {
            queryItems.append(URLQueryItem(name: "section", value: section))
        }
        if let item, !item.isEmpty {
            queryItems.append(URLQueryItem(name: "item", value: item))
        }
        components.queryItems = queryItems
        return components.url ?? URL(string: "\(Self.scheme)://\(Self.host)")!
    }
}

@MainActor
final class AppDeepLinkCenter: ObservableObject {
    @Published private(set) var route: AppDeepLink?

    func open(_ route: AppDeepLink) {
        self.route = route
    }
}
