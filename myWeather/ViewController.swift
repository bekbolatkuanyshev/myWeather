//
//  ViewController.swift
//  myWeather
//
//  Created by Бекболат Куанышев on 24.04.17.
//  Copyright © 2017 Bekbolat. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, SFSpeechRecognizerDelegate {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var conditionLabel: UILabel!
    @IBOutlet weak var degreeLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var record: UIBarButtonItem!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngene = AVAudioEngine()
    let imagePicker = UIImagePickerController()
    
    var degree: Int!
    var _date: Double?
    var _temp: String?
    var condition: String!
    var imgURL: String!
    var city: String!
    var exists: Bool = true
    
    var settings: SettingsView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(swipeActionLeft))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(swipeActionRight))
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(swipeRight)
        
        //settings = Bundle.main.loadNibNamed("Settings", owner: self, options: nil)?.last as! SettingsView
        //settings.frame = CGRect(x: 0, y: -self.view.frame.size.height + 66, width: self.view.frame.size.width, height: self.view.frame.size.height)
        //self.view.addSubview(settings)
        
        
        self.hideKeyboardWhenTappedAround()
        
        imagePicker.delegate = self
        searchBar.delegate = self
        record.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization {
            status in
            
            var buttonState = false
            
            switch status {
            case .authorized:
                buttonState = true
                print("Access")
            case .denied:
                buttonState = false
                print("Not Allowed")
            case .notDetermined:
                buttonState = false
                print("Don't Accessed")
            case .restricted:
                buttonState = false
                print("Doesn't compable")
            }
            
            DispatchQueue.main.async {
                self.record.isEnabled = buttonState
            }
        }
    }
    
    func swipeActionLeft () {
        backgroundImage.image = UIImage.init(named: "purple")
        self.viewDidLoad()
    }
    func swipeActionRight () {
        backgroundImage.image = UIImage.init(named: "blue")
        self.viewDidLoad()
    }
    // Audio Recording
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Can't cant audio session")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngene.inputNode else {
            fatalError("Can't start")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Can't create a dublicate")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) {
            
            result, error in
            
            var isFinal = false
            
            if result != nil {
                self.searchBar.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                self.searchBarSearchButtonClicked(self.searchBar)
            }
            
            if error != nil || isFinal {
                self.audioEngene.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.record.isEnabled = true
            }
        }
        
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
            buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngene.prepare()
        
        do {
            try audioEngene.start()
        } catch {
            print("Can't Start")
        }
        
        searchBar.text = "Slowly... I'm recording...."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            record.isEnabled = true
        } else {
            record.isEnabled = false
        }
    }
    
    @IBAction func recordPressed(_ sender: UIBarButtonItem) {
        if audioEngene.isRunning {
            audioEngene.stop()
            recognitionRequest?.endAudio()
            record.isEnabled = false
        } else {
            startRecording()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        let urlRequest = URLRequest(url: URL(string: "http://api.apixu.com/v1/current.json?key=d2363c261d5b40d4abf103908173004&q=\(searchBar.text!.replacingOccurrences(of: " ", with: "%20"))")!)
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            
            if error == nil {
                
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : AnyObject]
                    print (json)
                    if let current = json["current"] as? [String : AnyObject] {
                        
                        if let temp = current["temp_c"] as? Int {
                            self.degree = temp
                        }
                        if let condition = current["condition"] as? [String : AnyObject] {
                            self.condition = condition["text"] as! String
                            let icon = condition["icon"] as! String
                            self.imgURL = "http:\(icon)"
                        }
                    }
                    
                    if let location = json["location"] as? [String : AnyObject] {
                        let _city = location["name"] as! String
                        let _country = location["country"] as! String
                        let dt = location["localtime_epoch"] as! Double
                        self.city = _city + ", " + _country
                        self._date = dt
                    }
                    
                    if let _ = json["error"] {
                        self.exists = false
                    }
                    
                    DispatchQueue.main.async {
                        if self.exists {
                            self.dateLabel.isHidden = false
                            self.degreeLabel.isHidden = false
                            self.conditionLabel.isHidden = false
                            self.imgView.isHidden = false
                            
                            self.dateLabel.center.x -= self.view.frame.width - 30
                            self.degreeLabel.center.x = self.view.frame.width + 30
                            self.imgView.alpha = 0
                            self.conditionLabel.center.y = self.view.frame.width + 30
                            
                            UIView.animate(withDuration: 1.0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.5, animations: ({
                                
                                self.dateLabel.center.x = self.view.frame.width / 2
                                self.dateLabel.text = self.date
                                
                                self.degreeLabel.center.x = self.view.frame.width / 2
                                self.degreeLabel.text = self.degree.description + "° C"
                                
                                self.conditionLabel.center.y = self.view.frame.height - 141
                                self.conditionLabel.text = self.condition
                            }), completion: nil)
                            
                            UIView.animate(withDuration: 2.0, animations: ({
                                self.imgView.alpha = 1.0
                                self.imgView.dowloandImage(from: self.imgURL)
                            }), completion: nil)
                            
                            self.cityLabel.text = self.city
                            
                        } else {
                            self.cityLabel.text = "No matching city found"
                            self.dateLabel.isHidden = true
                            self.degreeLabel.isHidden = true
                            self.conditionLabel.isHidden = true
                            self.imgView.isHidden = true
                            self.exists = true
                        }
                    }
                    
                }
                catch let jsonError {
                    print(jsonError.localizedDescription)
                    
                }
            }
            
        }
        task.resume()
    }
    var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let date = Date(timeIntervalSince1970: _date!)
        return (_date != nil) ? "Today, \(dateFormatter.string(from: date))" : "Date Invalid"
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


