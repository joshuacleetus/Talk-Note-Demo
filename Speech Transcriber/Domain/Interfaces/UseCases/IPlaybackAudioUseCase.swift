//
//  IPlaybackAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import AVFoundation

protocol IPlaybackAudioUseCase {
    func execute() -> Observable<Bool>
    func stop()
    func getCurrentTime() -> TimeInterval
    func isPlaying() -> Bool
    func setDelegate(_ delegate: AVAudioPlayerDelegate)
}
