//
//  RecordingState.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation

enum RecordingState: Equatable {
    case idle
    case loading
    case recording
    case playing
    case error(String)
    case processingTranscription
    
    // Add this for Equatable conformance with associated values
    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.recording, .recording), (.playing, .playing),
             (.processingTranscription, .processingTranscription):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}
