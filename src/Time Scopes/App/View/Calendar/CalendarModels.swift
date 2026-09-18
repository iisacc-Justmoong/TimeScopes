//
//  CalendarModels.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-06.
//

import Foundation
import SwiftUI

struct MonthMetadata {
    let monthStart: Date
    let daysInMonth: Int
    let leadingEmptyDays: Int
}

struct CalendarMarker: Identifiable {
    let id = UUID()
    let color: Color
}

struct AgendaItem: Identifiable {
    enum Kind {
        case event
        case reminder
        case journal
    }

    let id: String
    let kind: Kind
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color
}
