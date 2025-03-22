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
            VStack(spacing: 16) {
                // Title at the top
                Text("Speech Transcriber")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Transcription text in a box
                VStack {
                    if viewModel.transcriptionText.isEmpty {
                        Text("Record audio to see transcription here")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        TranscriptionTextView(
                            text: viewModel.transcriptionText,
                            highlightedWordIndex: viewModel.highlightedWordIndex
                        )
                        .padding()
                    }
                }
                .frame(minHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 20) {
                    RecordingButton(
                        recordingState: viewModel.recordingState,
                        onTap: viewModel.toggleRecording
                    )
                    
                    // Playback button only enabled if we have a transcription
                    Button(action: viewModel.togglePlayback) {
                        HStack {
                            Image(systemName: viewModel.recordingState == .playing ? "stop.fill" : "play.fill")
                            Text(viewModel.recordingState == .playing ? "Stop" : "Play")
                        }
                        .frame(width: 120, height: 50)
                        .background(viewModel.recordingState == .playing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    .disabled(viewModel.transcriptionText.isEmpty)
                    .opacity(viewModel.transcriptionText.isEmpty ? 0.5 : 1)
                }
                .padding(.bottom, 100)
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

#Preview {
    // Use dependency container to get use cases
    let container = DependencyContainer.shared
    
    // Create view model using use cases from container
    let viewModel = TranscriptionViewModel(
        recordAudioUseCase: container.recordAudioUseCase,
        transcribeAudioUseCase: container.transcribeAudioUseCase,
        playbackAudioUseCase: container.playbackAudioUseCase
    )
    
    return TranscriptionView(viewModel: viewModel)
}
