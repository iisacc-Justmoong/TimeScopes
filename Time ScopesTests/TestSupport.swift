import Foundation
@testable import Time_Scopes

enum TestDateFactory {
    static let gmt = TimeZone(secondsFromGMT: 0)!

    static func makeCalendar(timeZone: TimeZone = gmt) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func date(_ value: String, timeZone: TimeZone = gmt) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = makeCalendar(timeZone: timeZone)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: value) else {
            fatalError("Invalid test date: \(value)")
        }
        return date
    }
}

struct FixedDateProvider: DateProviding {
    let fixedNow: Date
    let calendar: Calendar

    init(now: Date, calendar: Calendar) {
        fixedNow = now
        self.calendar = calendar
    }

    func now() -> Date {
        fixedNow
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func today() -> Date {
        startOfDay(for: fixedNow)
    }

    func daysInYear(for date: Date) -> Int {
        calendar.range(of: .day, in: .year, for: date)?.count ?? 365
    }
}

final class InMemoryUserProfileStore: UserProfileStoring {
    var savedProfile: UserProfile?

    init(initialProfile: UserProfile? = nil) {
        savedProfile = initialProfile
    }

    func loadProfile() -> UserProfile? {
        savedProfile
    }

    func saveProfile(_ profile: UserProfile) {
        savedProfile = profile
    }
}
