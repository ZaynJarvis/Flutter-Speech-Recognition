# Speech Recognition Flutter in 2018

This project intends to instruct Flutter developers to use Speech Recognition.

This project gives credit to [rxlabz/sytody](https://github.com/rxlabz/sytody)

* Android Setup

    1. The first thing you should do is add permission in AndroidManifest.xml in [android/app/src/main](./android/app/src/main/AndroidManifest.xml)

    2. Next thing to do is to add Platform Channel in dart. Refer to [recognizer.dart](./lib/recognizer.dart).

    3. Add Platform Channel solution to MainActivity.java in [android/app/src/main/java/com/example/speechrecognition/MainActivity.java](android/app/src/main/java/com/example/speechrecognition/MainActivity.java).

    4. The folder under /main/java may be different, it depends on your java configuration.

    5. The only essential difference in MainActivity.java is **requestRecordAudioPermission** function, since android sdk increase the permission security level in sdk 27.

    6. Add custom layout and styling to your flutter frontend.

* IOS Setup

    1. `flutter create speech -i swift`
    2. add to /ios/Runner/Info.plist
    ```xml
    <key>NSMicrophoneUsageDescription</key>
    <string>This application needs to access your microphone</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>This application needs the speech recognition permission</string>
    ```
    3. add to /ios/Runner/AppDelegate.swift
    ```swift
    import UIKit
    import Flutter
    import Speech

    @UIApplicationMain
    class AppDelegate: FlutterAppDelegate, SFSpeechRecognizerDelegate {

    private let speechRecognizerEn = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))!

    private var speechChannel: FlutterMethodChannel?

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    private var recognitionTask: SFSpeechRecognitionTask?

    private let audioEngine = AVAudioEngine()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

        speechChannel = FlutterMethodChannel.init(name: "speech_recognizer",
        binaryMessenger: controller)
        speechChannel!.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if ("start" == call.method) {
            self.startRecognition(lang: call.arguments as! String, result: result)
        } else if ("stop" == call.method) {
            self.stopRecognition(result: result)
        } else if ("cancel" == call.method) {
            self.cancelRecognition(result: result)
        } else if ("activate" == call.method) {
            self.activateRecognition(result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
        })
        return true
    }

    func activateRecognition(result: @escaping FlutterResult) {
        speechRecognizerEn.delegate = self
        speechRecognizerIt.delegate = self

        SFSpeechRecognizer.requestAuthorization { authStatus in
        OperationQueue.main.addOperation {
            switch authStatus {
            case .authorized:
            result(true)

            case .denied:
            result(false)

            case .restricted:
            result(false)

            case .notDetermined:
            result(false)
            }
        }
        }
    }

    private func startRecognition(lang: String, result: FlutterResult) {
        if audioEngine.isRunning {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        result(false)
        } else {
        try! start(lang: lang)
        result(true)
        }
    }

    private func cancelRecognition(result: FlutterResult?) {
        if let recognitionTask = recognitionTask {
        recognitionTask.cancel()
        self.recognitionTask = nil
        if let r = result {
            r(false)
        }
        }
    }

    private func stopRecognition(result: FlutterResult) {
        if audioEngine.isRunning {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        }
        result(false)
    }

    private func start(lang: String) throws {

        cancelRecognition(result: nil)

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let inputNode = audioEngine.inputNode else {
        fatalError("Audio engine has no input node")
        }
        guard let recognitionRequest = recognitionRequest else {
        fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object")
        }

        recognitionRequest.shouldReportPartialResults = true

        let speechRecognizer = getRecognizer(lang: lang)

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
        var isFinal = false

        if let result = result {
            print("Speech : \(result.bestTranscription.formattedString)")
            self.speechChannel?.invokeMethod("onSpeech", arguments: result.bestTranscription.formattedString)
            isFinal = result.isFinal
            if isFinal {
            self.speechChannel!.invokeMethod(
                "onRecognitionComplete",
                arguments: result.bestTranscription.formattedString
            )
            }
        }

        if error != nil || isFinal {
            self.audioEngine.stop()
            inputNode.removeTap(onBus: 0)
            self.recognitionRequest = nil
            self.recognitionTask = nil
        }
        }

        let RecognitionFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: RecognitionFormat) {
        (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
        self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        speechChannel!.invokeMethod("onRecognitionStarted", arguments: nil)
    }

    private func getRecognizer(lang: String) -> Speech.SFSpeechRecognizer {
        return speechRecognizerEn
    }

    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
        speechChannel?.invokeMethod("onSpeechAvailability", arguments: true)
        } else {
        speechChannel?.invokeMethod("onSpeechAvailability", arguments: false)
        }
    }

    }

    ```
> Because of iOS updated to 12.0.1 and swift updated to 4.0, iOS feature is not correctly implemented yet.

---
**For this feature to work correctly, you may need to have Google App run in the background.**
