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
        VStack(spacing: 20) {
            // Transcription text display
            TranscriptionTextView(
                text: viewModel.transcriptionText,
                highlightedWordIndex: viewModel.highlightedWordIndex
            )
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            
            // Status and error messages
            if case let .error(message) = viewModel.recordingState {
                Text(message)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Loading indicator
            if case .loading = viewModel.recordingState {
                LoadingView()
                    .frame(width: 50, height: 50)
            }
            
            // Control buttons
            HStack(spacing: 40) {
                // Record button
                RecordingButton(
                    isRecording: viewModel.recordingState == .recording,
                    isEnabled: viewModel.recordingState == .idle || viewModel.recordingState == .recording,
                    action: viewModel.toggleRecording
                )
                
                // Play button
                Button(action: viewModel.togglePlayback) {
                    HStack {
                        Image(systemName: viewModel.recordingState == .playing ? "stop.fill" : "play.fill")
                        Text(viewModel.recordingState == .playing ? "Stop" : "Play")
                    }
                    .frame(width: 120, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
                .disabled(viewModel.recordingState != .idle && viewModel.recordingState != .playing)
                .opacity(viewModel.recordingState != .idle && viewModel.recordingState != .playing ? 0.5 : 1)
            }
            .padding(.bottom, 30)
            
            // In TranscriptionView
            Button("Test with Sample") {
                viewModel.testTranscriptionWithSampleAudio()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button(action: {
                viewModel.playTestSound()
            }) {
                Text("Test Sound")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
        .navigationTitle("Speech Transcriber")
        .accessibilityElement(children: .combine)
        
    }
}
