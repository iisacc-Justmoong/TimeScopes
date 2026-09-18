//
//  GradientBackgroundModifier.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import SwiftUI

struct LeftGradientBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.orange.opacity(0.6), location: 0.1),
                .init(color: Color.indigo.opacity(0.2), location: 0.3),
                .init(color: Color(UIColor.systemGroupedBackground), location: 0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
