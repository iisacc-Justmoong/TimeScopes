//
//  PulseView.swift
//  Time Scopes
//
//  Created by OpenAI on 2026-02-03.
//

import SwiftUI

struct PulseView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "waveform")
                    .font(.system(size: 42, weight: .semibold))
                Text("Pulse")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Coming soon.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassScreen()
        }
    }
}

#Preview {
    PulseView()
}
