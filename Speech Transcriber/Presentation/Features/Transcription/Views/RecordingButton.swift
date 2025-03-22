//
//  RecordingButton.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

struct RecordingButton: View {
    let recordingState: RecordingState
    let onTap: () -> Void
    
    private var isRecording: Bool {
        if case .recording = recordingState {
            return true
        }
        return false
    }
    
    private var isEnabled: Bool {
        switch recordingState {
        case .idle, .recording:
            return true
        case .loading, .playing, .error, .processingTranscription:
            return false
        }
    }
    
    var body: some View {
        Button(action: onTap) {
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
