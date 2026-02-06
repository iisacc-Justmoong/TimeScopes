//
//  SunEventCalculator.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import CoreLocation
import Foundation

enum SunEventKind {
    case sunrise
    case sunset
}

struct SunEventWindow {
    let nextEvent: SunEventKind
    let nextDate: Date
    let previousDate: Date
}

enum SunEventCalculator {
    static func nextEventWindow(
        for date: Date,
        location: CLLocation,
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) -> SunEventWindow? {
        var localCalendar = calendar
        localCalendar.timeZone = timeZone

        guard let todayTimes = sunTimes(for: date, location: location, calendar: localCalendar, timeZone: timeZone) else {
            return nil
        }

        if date < todayTimes.sunrise {
            let previousDate = localCalendar.date(byAdding: .day, value: -1, to: date) ?? date
            let previousSunset = sunTimes(for: previousDate, location: location, calendar: localCalendar, timeZone: timeZone)?.sunset ?? todayTimes.sunrise
            return SunEventWindow(nextEvent: .sunrise, nextDate: todayTimes.sunrise, previousDate: previousSunset)
        }

        if date < todayTimes.sunset {
            return SunEventWindow(nextEvent: .sunset, nextDate: todayTimes.sunset, previousDate: todayTimes.sunrise)
        }

        let nextDate = localCalendar.date(byAdding: .day, value: 1, to: date) ?? date
        guard let nextTimes = sunTimes(for: nextDate, location: location, calendar: localCalendar, timeZone: timeZone) else {
            return nil
        }
        return SunEventWindow(nextEvent: .sunrise, nextDate: nextTimes.sunrise, previousDate: todayTimes.sunset)
    }

    private static func sunTimes(
        for date: Date,
        location: CLLocation,
        calendar: Calendar,
        timeZone: TimeZone
    ) -> (sunrise: Date, sunset: Date)? {
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        let gamma = 2.0 * Double.pi / 365.0 * (Double(dayOfYear) - 1.0)
        let eqTime = 229.18 * (
            0.000075
            + 0.001868 * cos(gamma)
            - 0.032077 * sin(gamma)
            - 0.014615 * cos(2.0 * gamma)
            - 0.040849 * sin(2.0 * gamma)
        )
        let decl = 0.006918
            - 0.399912 * cos(gamma)
            + 0.070257 * sin(gamma)
            - 0.006758 * cos(2.0 * gamma)
            + 0.000907 * sin(2.0 * gamma)
            - 0.002697 * cos(3.0 * gamma)
            + 0.00148 * sin(3.0 * gamma)

        let latRad = degreesToRadians(latitude)
        let zenith = degreesToRadians(90.833)
        let cosH = (cos(zenith) / (cos(latRad) * cos(decl))) - tan(latRad) * tan(decl)
        guard cosH <= 1, cosH >= -1 else {
            return nil
        }

        let ha = acos(cosH)
        let haDegrees = radiansToDegrees(ha)
        let tzHours = Double(timeZone.secondsFromGMT(for: date)) / 3600.0
        let solarNoonMinutes = 720 - 4 * longitude - eqTime + tzHours * 60
        let sunriseMinutes = solarNoonMinutes - haDegrees * 4
        let sunsetMinutes = solarNoonMinutes + haDegrees * 4

        let startOfDay = calendar.startOfDay(for: date)
        let sunrise = startOfDay.addingTimeInterval(sunriseMinutes * 60)
        let sunset = startOfDay.addingTimeInterval(sunsetMinutes * 60)

        return (sunrise: sunrise, sunset: sunset)
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * Double.pi / 180.0
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180.0 / Double.pi
    }
}
