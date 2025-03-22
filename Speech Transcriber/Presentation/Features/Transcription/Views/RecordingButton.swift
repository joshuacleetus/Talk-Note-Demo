//
//  RecordingButton.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

struct RecordingButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                Text(isRecording ? "Stop" : "Record")
            }
            .frame(width: 120, height: 50)
            .background(isRecording ? Color.gray : Color.red)
            .foregroundColor(.white)
            .cornerRadius(25)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
        .accessibilityHint(isRecording ? "Stops the current recording" : "Starts recording your voice")
    }
}
