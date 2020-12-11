//
//  ReceivedSketchViewController.swift
//  illustalk
//
//  Created by YutaroSakai on 2020/11/01.
//

import UIKit
import Sketch

class ReceivedSketchViewController: UIViewController {
    
    @IBOutlet weak var sketchImageView: UIImageView!
    @IBOutlet weak var senderNameLabel: UILabel!
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    var receivedSketchImage: UIImage!
    var senderPeerId: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sketchImageView.image = receivedSketchImage
        senderNameLabel.text = "イラストが送られてきました"
    }
}
