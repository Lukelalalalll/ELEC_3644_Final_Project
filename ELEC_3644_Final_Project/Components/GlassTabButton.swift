//
//  GlassTabButtonView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//

import SwiftUI

struct GlassTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolVariant(isSelected ? .fill : .none)
                
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        GlassTabButton(icon: "house", title: "Home", isSelected: true) {}
        GlassTabButton(icon: "book", title: "Courses", isSelected: false) {}
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
