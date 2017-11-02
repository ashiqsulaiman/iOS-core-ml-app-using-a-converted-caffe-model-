//
//  ViewController.swift
//  FlowerFinder
//
//  Created by Ashiq Sulaiman on 27/10/17.
//  Copyright © 2017 Ashiq Sulaiman. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SwiftyJSON
import Alamofire
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    let imagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php?"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .savedPhotosAlbum //change to camera for using the phone camera
        imageView.contentMode = .scaleAspectFit
        
        
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("cannot convert image to ciimage")
        }
            detect(flower: ciImage)
            //imageView.image = userPickedImage
        //Dismiss image picker after taking the picture
        imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func detect(flower: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("failed to import the model FLower classifier")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification  = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify the image")
            }
            self.navigationItem.title = classification.identifier.capitalized
            self.getFlowerInformation(flowerName: classification.identifier)
            
        }
        
        // handler to process the request
        // handler runs first and then the closure inside the request is executed
        let handler = VNImageRequestHandler(ciImage: flower)
        
        do {
            try handler.perform([request])
        }catch {
            print("error")
        }
        
    }
    
    func getFlowerInformation(flowerName: String){
        let parameters: [String : String] = ["format" : "json",
                                             "action" : "query",
                                             "prop"   : "extracts|pageimages",
                                             "exintro" : "",
                                             "explaintext" : "",
                                             "titles" : flowerName,
                                             "indexpageids" : "",
                                             "redirects" : "1",
                                             "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess{
               // print(response.result.value)
                let flowerJSON: JSON = JSON(response.result.value!)
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.flowerDescriptionLabel.text = flowerDescription
            }
        }
        
    }
    
    @IBAction func takePicture(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

