//
//  GlassStyle.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

enum GlassStyle {
    static let cornerRadius: CGFloat = 18
    static let cardPadding = EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    static let strokeGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.55),
            Color.white.opacity(0.18),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let shadowColor = Color.black.opacity(0.16)
}

struct GlassScreenBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.25),
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [
                    Color.white.opacity(0.4),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 320
            )
            .blendMode(.screen)
            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.18),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

struct GlassCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius, style: .continuous)
                    .stroke(GlassStyle.strokeGradient, lineWidth: 1)
            )
            .shadow(color: GlassStyle.shadowColor, radius: 14, x: 0, y: 8)
    }
}

extension View {
    func glassCard(padding: EdgeInsets = GlassStyle.cardPadding) -> some View {
        self
            .padding(padding)
            .background(GlassCardBackground())
            .contentShape(RoundedRectangle(cornerRadius: GlassStyle.cornerRadius, style: .continuous))
    }

    func glassRow() -> some View {
        self
            .listRowBackground(Rectangle().fill(.ultraThinMaterial))
    }

    func glassScreen() -> some View {
        self
            .background(GlassScreenBackground())
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}
