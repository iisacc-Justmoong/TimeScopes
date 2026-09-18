//
//  RightGradientBackgroundView.swift
//  Life Taker
//
//  Created by ymy on 2/13/25.
//

import SwiftUI

struct RightGradientBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.mint.opacity(0.6), location: 0.0),
                .init(color: Color.pink.opacity(0.2), location: 0.3),
                .init(color: Color(UIColor.systemGroupedBackground), location: 0.95)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
