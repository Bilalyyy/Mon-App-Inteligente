//
//  ViewController.swift
//  Mon App Inteligente
//
//  Created by bilal on 28/12/2021.
//

import UIKit
import PhotosUI
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var prImage: UIImageView!
    @IBOutlet weak var prLblTitre: UILabel!
    @IBOutlet weak var prLblDescription: UILabel!
    
    var picker: PHPickerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        picker = PHPickerViewController(configuration: setupPickerConfiguration())
        picker?.delegate = self
    }
    
    
    func getCoreML() -> VNCoreMLModel? {
        let config = MLModelConfiguration()
        do {
            let ml = try SqueezeNet(configuration: config)
            let model = try VNCoreMLModel(for: ml.model)
            return model
        } catch {
            print("Une erreur c'est produite \(error.localizedDescription)")
            return nil
        }
    }
    
    
    
    func getCiImage() -> CIImage? {
        if let image = prImage.image {
            if let sCiImage = CIImage(image: image) {
                return sCiImage
            }
        }
        return nil
    }
    
    func setupRequest(_ model: VNCoreMLModel)-> VNCoreMLRequest {
        return VNCoreMLRequest(model: model, completionHandler: setupResultHandler(_:_:))
    }
    
    
    func setupResultHandler(_ vnRequest: VNRequest, _ error: Error?) {
        let results = vnRequest.results as? [VNClassificationObservation]
        if let bestResult = results?.first {
            self.updateLbl(bestResult.identifier, bestResult.confidence)
        }
    }
    
    func updateLbl(_ identifier: String,_ confidence: Float) {
        DispatchQueue.main.async {
            self.prLblDescription.text = "c'est un: \(identifier)!\nJ'en suis sur a \(Int(confidence * 100))%"
        }
        
    }
    
    func setupHandler(_ image: CIImage, request: VNCoreMLRequest) {
        DispatchQueue.global(qos: .userInitiated).async { // requete lancé en background
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("La requete n'a pas aboutie \(error.localizedDescription)")
            }
        }
    }
    
    
    
    @IBAction func btnImporter(_ sender: Any) {
        if let sPicker = picker {
            present(sPicker, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func btnAnalyser(_ sender: Any) {
        guard let ciImage = getCiImage() else  {return}
        guard let model = getCoreML() else {return} // mise en place de la requete Vision
        let request = setupRequest(model)
        setupHandler(ciImage, request: request)
    }
    
    
    //.
}


extension ViewController: PHPickerViewControllerDelegate {
    
    func setupPickerConfiguration()-> PHPickerConfiguration {
        var config = PHPickerConfiguration()
        config.preferredAssetRepresentationMode = .automatic
        config.selectionLimit = 1
        config.filter = .images
        
        return config
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let result = results.first else {return}
        let item = result.itemProvider
        guard item.canLoadObject(ofClass: UIImage.self) else {return}
        item.loadObject(ofClass: UIImage.self) { bridgeable, error in
            if let sError = error {
                print("Une erreur c'est produite: \(sError.localizedDescription)")
            }
            if let image = bridgeable as? UIImage {
                DispatchQueue.main.async {
                    self.prImage.image = image
                }
            }
        }
    }
    
    
}
