//
//  ViewController.swift
//  Flower?
//
//  Created by Avilash on 09/12/18.
//  Copyright © 2018 Avilash. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    
    @IBOutlet weak var label: UILabel!
    
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        label.isHidden = true
        
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let userPickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            
            
            label.isHidden = false

            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Error in converting UIImage into CIImage.")
            }
            detect(image: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }

    //MARK:- Detect Method
    
    func detect (image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Fails.")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
           
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Classification Error")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        } catch {
            print("Error in Handling Image \(error)")
        }
        
        
        }
    
    //MARK :- AlamoFire Request.
    
    func requestInfo (flowerName: String) {
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
            ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                
                print("We Got The Results")
                
                print(response)
            }
            
            let flowerJSON: JSON = JSON(response.result.value!)

            let pageID = flowerJSON["query"]["pageids"][0].stringValue
            
            let flowerDiscription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
            
            let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
            
            self.photoImageView.sd_setImage(with: URL(string: flowerImageURL))
            
            self.label.text = flowerDiscription

        }
        
    }
    


    @IBAction func cameraButton(_ sender: Any) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
}

