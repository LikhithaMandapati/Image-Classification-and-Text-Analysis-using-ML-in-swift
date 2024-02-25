//
//  ViewController.swift
//  Exrecise8_Mandapati_Likhitha
//
//  Created by student on 11/12/22.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {

    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var shuffleImgButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    
    var images = ["news", "news1", "news2", "news3", "cat" ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imgView.image = UIImage(named: "news")
        classifyImage()
        
        shuffleImgButton.tintColor = UIColor(red: 22/255, green: 199/255, blue: 154/255, alpha: 1)
        textButton.tintColor = UIColor(red: 22/255, green: 199/255, blue: 154/255, alpha: 1)
        
        shuffleImgButton.contentVerticalAlignment = .fill
        shuffleImgButton.contentHorizontalAlignment = .fill
        
        textButton.contentVerticalAlignment = .fill
        textButton.contentHorizontalAlignment = .fill
    }
    
    func classifyImage() {
        guard let ciImage = CIImage(image: imgView.image!) else {
            fatalError("failed to convert UIImage to CIImage!")
        }
        let config = MLModelConfiguration()
        guard let model = try? VNCoreMLModel(for: Resnet50(configuration: config).model) else {
            fatalError("failed to load ML model!")
        }
        classificationLabel.text = "Classifying image..."
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            let results = request.results as? [VNClassificationObservation]
            var classificationResulltText = ""
            for result in results! {
                classificationResulltText += "\(Int(result.confidence * 100))% \(result.identifier) \n"
            }
            
            DispatchQueue.main.async {
                self?.classificationLabel.text! = classificationResulltText
            }
        }
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        var secondViewController = (self.tabBarController?.viewControllers![1])! as? TextViewController
        secondViewController?.inputField.text = self.classificationLabel.text
        secondViewController?.nlpOutlet.text = ""
    }

    @IBAction func shuffleImage(_ sender: Any) {
        imgView.image = UIImage(named: images.randomElement()!)
        classifyImage()
        
    }
    
    @IBAction func analyzeText(_ sender: Any) {
        if let cgImage = imgView.image?.cgImage {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            
            let recognizeTextRequest = VNRecognizeTextRequest {
                (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    return
                }
                
                let recognizedStrings = observations.compactMap {
                    observation in
                    observation.topCandidates(1).first?.string
                }
                
                DispatchQueue.main.async {
                    self.classificationLabel.text = recognizedStrings.joined(separator: ", ")
                    
                    if recognizedStrings.count == 0 {
                        self.classificationLabel.text = "Text has not been recognized. Please make sure that image has any text, has high enough resolution, has readable text on it, is bright enough"
                    }
                }
            }
            recognizeTextRequest.recognitionLevel = .fast
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try requestHandler.perform([recognizeTextRequest])
                } catch{
                    print(error)
                }
            }
        }
    }
}

