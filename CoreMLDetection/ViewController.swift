//
//  ViewController.swift
//  CoreMLDetection
//
//  Created by Jonathan Sagorin on 22/6/17.
/*
 Copyright © 2017 Jonathan Sagorin.
 
 This is sample code
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 
 */
import UIKit
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var pickedImageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    
    let coreMLModel = Resnet50()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let pickedImage = self.pickedImageView.image {
            classifyImage(image: pickedImage)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - User actions
    @IBAction func pickImageTapped(_ sender: UIBarButtonItem) {
        let pickImageController = UIImagePickerController()
        pickImageController.delegate = self
        pickImageController.sourceType = .savedPhotosAlbum
        present(pickImageController, animated: true)
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIBarButtonItem) {
        let pickImageController = UIImagePickerController()
        pickImageController.delegate = self
        pickImageController.sourceType = .camera
        pickImageController.cameraCaptureMode = .photo
        present(pickImageController, animated: true)
    }
    
    /// Classify this image using a pre-trained Core ML model
    ///
    /// - Parameter image: picked image
    func classifyImage(image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            print("could not continue - no CiImage constructed")
            return
        }
        
        resultLabel.text = "classifying..."
        
        guard let trainedModel = try? VNCoreMLModel(for: coreMLModel.model) else {
            print("can't load ML model")
            return
        }
        
        let classificationRequest = VNCoreMLRequest(model: trainedModel) { [weak self] classificationRequest, error in
            guard let results = classificationRequest.results as? [VNClassificationObservation],
                let firstResult = results.first else {
                    print("unexpected result type from VNCoreMLRequest")
                    return
            }
            //for debug purposes - print all the classification results as a confidence percentage
            print("classifications: \(results.count)")
            let classifications = results
                //        .filter({ $0.confidence &gt; 0.001 })
                .map({ "\($0.identifier) \(String(format:"%.10f%%", Float($0.confidence)*100))" })
            print(classifications.joined(separator: "\n"))
            //display first result only as a percentage (highest classification)
            DispatchQueue.main.async { [weak self] in
                self?.resultLabel.text = "\(Int(firstResult.confidence * 100))% \(firstResult.identifier)"
            }
        }
        //perform an image request
        let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try imageRequestHandler.perform([classificationRequest])
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        dismiss(animated: true)
        
        guard let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            print("pickedImage is nil")
            return
        }
        pickedImageView.image = pickedImage
        classifyImage(image: pickedImage)
    }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
    //ViewController must implement UINavigationControllerDelegate to allow for presentation/dismissal of UINavigationControllerUIImagePickerControllerDelegate
}


