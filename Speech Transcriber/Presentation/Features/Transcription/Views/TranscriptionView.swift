//
//  TranscriptionView.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

struct TranscriptionView: View {
    @ObservedObject var viewModel: TranscriptionViewModel
    
    var body: some View {
        ZStack {
            // Main content
            VStack {
                TranscriptionTextView(
                    text: viewModel.transcriptionText,
                    highlightedWordIndex: viewModel.highlightedWordIndex
                )
                .padding()
                
                HStack {
                    RecordingButton(
                        recordingState: viewModel.recordingState,
                        onTap: viewModel.toggleRecording
                    )
                    
                    // Playback button only enabled if we have a transcription
                    Button(action: viewModel.togglePlayback) {
                        Image(systemName: viewModel.recordingState == .playing ? "stop.fill" : "play.fill")
                            .font(.title)
                            .foregroundColor(viewModel.transcriptionText.isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.transcriptionText.isEmpty)
                }
                .padding()
            }
            
            // Overlay for loading and error states
            if case .loading = viewModel.recordingState {
                LoadingView(message: "Processing...")
            } else if case .processingTranscription = viewModel.recordingState {
                LoadingView(message: "Transcribing audio...")
            } else if case .error(let message) = viewModel.recordingState {
                ErrorView(
                    message: message,
                    dismissAction: viewModel.dismissError
                )
            }
        }
    }
}
