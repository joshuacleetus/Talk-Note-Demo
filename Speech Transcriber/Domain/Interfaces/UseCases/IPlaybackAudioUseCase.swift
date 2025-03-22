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
    func setDelegate(_ delegate: AVAudioPlayerDelegate)
    func isPlaying() -> Bool
    func getCurrentTime() -> TimeInterval
    
    // Add this property to the protocol
    var currentTimeObservable: Observable<TimeInterval> { get }
}
