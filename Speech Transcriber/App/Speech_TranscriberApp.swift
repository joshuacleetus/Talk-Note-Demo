//
//  Speech_TranscriberApp.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

@main
struct SpeechTranscriberApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TranscriptionView(viewModel: DependencyContainer.shared.makeTranscriptionViewModel())
            }
        }
    }
}
