//
//  ViewController.swift
//  Siri
//
//  Created by Sahand Edrisian on 7/14/16.
//  Copyright © 2016 Sahand Edrisian. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

class ViewController: UIViewController, SFSpeechRecognizerDelegate, AVSpeechSynthesizerDelegate {
	
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var microphoneButton: UIButton!
    
    var timer = Timer()
	
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private let synthesizer = AVSpeechSynthesizer()
    
	override func viewDidLoad() {
        super.viewDidLoad()
        
//        microphoneButton.isEnabled = false
        
        speechRecognizer.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
//            OperationQueue.main.addOperation() {
//                self.microphoneButton.isEnabled = isButtonEnabled
//            }
        }
        
        textView.text = "Say something, I'm listening!"
        
        self.speakNow(input: self.textView.text)
        
        self.synthesizer.delegate = self
	}
    
    var startTime = Date()
    func twosecondsInterval() {
        let end = Date();
        
        let difference = end.timeIntervalSince(startTime)
        
        if(difference >= 0.5 && self.textView.text != "Say something, I'm listening!"){
            print(" time to stop the speech recognition ")
            self.timer.invalidate()
            
            audioEngine.stop()
            recognitionRequest?.endAudio()
//            microphoneButton.isEnabled = false
//            microphoneButton.setTitle("Start Recording", for: .normal)
            
            return;
        }
        
        print("Time to do something: \(difference) seconds");
        
        startTime = end;
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
//            microphoneButton.isEnabled = false
//            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
//            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
	}

    func startRecording() {
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { timer in
            self.twosecondsInterval()
        }
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }  //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                self.textView.text = result?.bestTranscription.formattedString  //9
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
//                self.microphoneButton.isEnabled = true
                
                self.speakNow(input: self.textView.text)
            }
            
            self.startTime = Date();
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        print("availabilityDidChange")
        
//        if available {
//            microphoneButton.isEnabled = true
//        } else {
//            microphoneButton.isEnabled = false
//        }
    }
    
    func speakNow(input:String) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback)
            try audioSession.setActive(false, with: .notifyOthersOnDeactivation)
        }
        catch {
            print("error in audiosession")
        }
        
        let utterance = AVSpeechUtterance(string:input)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        // utterance.rate = 0.5
        
        self.synthesizer.speak(utterance)
        print("speaking end");
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.textView.text = ""
        startRecording()
//        microphoneButton.setTitle("Stop Recording", for: .normal)
    }
    
}

