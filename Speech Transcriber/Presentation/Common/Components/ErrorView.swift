//
//  ErrorView.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/22/25.
//

import SwiftUI

struct ErrorView: View {
    // Properties
    let message: String
    let dismissAction: () -> Void
    let retryAction: (() -> Void)?
    
    // Initialize with optional retry action
    init(message: String, dismissAction: @escaping () -> Void, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.dismissAction = dismissAction
        self.retryAction = retryAction
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            // Error dialog
            VStack(spacing: 20) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                
                // Error title
                Text("Error")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Error message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Action buttons
                HStack(spacing: 16) {
                    // Dismiss button (always present)
                    Button(action: dismissAction) {
                        Text("Dismiss")
                            .fontWeight(.medium)
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    // Retry button (only if retry action provided)
                    if let retryAction = retryAction {
                        Button(action: retryAction) {
                            Text("Retry")
                                .fontWeight(.medium)
                                .frame(minWidth: 100)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
            )
            .padding(30)
            // Add a subtle shake animation for emphasis
            .modifier(ShakeEffect(animatableData: CGFloat(1)))
        }
        .transition(.opacity)
        .animation(.easeInOut, value: message)
    }
}

// Preview
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with just dismiss action
            ErrorView(
                message: "Unable to process audio. Please check your microphone permissions.",
                dismissAction: {}
            )
            .previewDisplayName("Error - Dismiss Only")
            
            // Preview with retry action
            ErrorView(
                message: "Network connection failed. Please check your internet connection.",
                dismissAction: {},
                retryAction: {}
            )
            .previewDisplayName("Error - With Retry")
            .preferredColorScheme(.dark)
        }
    }
}
