//
//  TranscriptionTextView.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import SwiftUI

struct TranscriptionTextView: View {
    let text: String
    let highlightedWordIndex: Int?
    
    @State private var attributedText: AttributedString = AttributedString("")
    
    var body: some View {
        ScrollView {
            Text(attributedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .onChange(of: text) {
            updateAttributedText()
        }
        .onChange(of: highlightedWordIndex) {
            updateAttributedText()
        }
        .onAppear {
            updateAttributedText()
        }
        .accessibilityLabel("Transcription text: \(text)")
    }
    
    private func updateAttributedText() {
        var attributed = AttributedString(text)
        
        if let highlightIndex = highlightedWordIndex {
            let words = text.split(separator: " ")
            
            if highlightIndex < words.count {
                let wordToHighlight = String(words[highlightIndex])
                
                if let range = attributed.range(of: wordToHighlight) {
                    attributed[range].backgroundColor = .yellow
                    attributed[range].foregroundColor = .black
                    attributed[range].font = .boldSystemFont(ofSize: 18)
                }
            }
        }
        
        attributedText = attributed
    }
}
