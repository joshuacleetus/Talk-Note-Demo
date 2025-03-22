//
//  LoadingView.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

struct LoadingView: View {
    @State private var isAnimating = false
    let message: String
    
    // Add an initializer with a default message
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading spinner
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.25), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.blue, lineWidth: 4)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    // Use the newer animation(_:value:) modifier
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }
            .frame(width: 50, height: 50)
            
            // Message text
            Text(message)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5)
        )
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Loading: \(message)")
    }
}
