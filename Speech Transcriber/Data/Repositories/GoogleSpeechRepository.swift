//
//  GoogleSpeechRepository.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

class GoogleSpeechRepository: ISpeechRecognitionRepository {
    private let googleSpeechService: GoogleSpeechService
    
    init(googleSpeechService: GoogleSpeechService) {
        self.googleSpeechService = googleSpeechService
    }
    
    func recognizeSpeech(fromAudioData data: Data, sampleRate: Int = 44100) -> Observable<[TranscribedWord]> {
        return googleSpeechService.recognizeSpeech(audioData: data, sampleRate: sampleRate)
            .do(onNext: { response in
                print("Full API response: \(response)")
                print("Number of result sections: \(response.results.count)")
            })
            .map { response -> [TranscribedWord] in
                // Create an array to hold all words from all results
                var allWords: [TranscribedWord] = []
                
                // Process ALL results, not just the first one
                for result in response.results {
                    guard let alternative = result.alternatives.first,
                          let wordInfos = alternative.words else {
                        continue
                    }
                    
                    let transcribedWords = wordInfos.map { wordInfo in
                        let startTime = self.googleSpeechService.parseTimeString(wordInfo.startTime)
                        let endTime = self.googleSpeechService.parseTimeString(wordInfo.endTime)
                        
                        return TranscribedWord(
                            text: wordInfo.word,
                            startTime: startTime,
                            endTime: endTime
                        )
                    }
                    
                    // Add words from this result to the full list
                    allWords.append(contentsOf: transcribedWords)
                }
                
                print("✅ Processed a total of \(allWords.count) words across all results")
                return allWords
            }
    }
}
