//
//  SketchViewController.swift
//  illustalk
//
//  Created by 斉藤大樹 on 2020/10/27.
//

import UIKit
import Sketch

class SketchViewController: UIViewController {
    
    var alert:UIAlertController!
    
    @IBAction func pencilButton(_ sender: Any) {
        sketchView.drawTool = .pen
        sketchView.lineAlpha = 1
        
        if(thickPencilButton.isEnabled){
            sketchView.lineWidth = CGFloat(5.0)
        }else{
            sketchView.lineWidth = CGFloat(10.0)
        }
        
        pencilButton.isEnabled = false
        eraserButton.isEnabled = true

    }
    
    
    @IBAction func eraserButton(_ sender: Any) {
        sketchView.drawTool = .eraser
        sketchView.lineAlpha = 0
        if(thickPencilButton.isEnabled){
            sketchView.lineWidth = CGFloat(5.0)
        }else{
            sketchView.lineWidth = CGFloat(20.0)
        }
        pencilButton.isEnabled = true
        eraserButton.isEnabled = false
    }
    
    @IBAction func allClearButton(_ sender: Any) {
        
        //アラートコントローラーを表示する。
        self.present(alert, animated: true, completion: nil)
    }

    
    @IBAction func thickPencilButton(_ sender: Any) {
        if(eraserButton.isEnabled){
            sketchView.lineWidth = CGFloat(10.0)
        }else{
            sketchView.lineWidth = CGFloat(20.0)
        }
        
        
        thickPencilButton.isEnabled = false
        thinPencilButton.isEnabled = true
    }
    
    
    @IBAction func thinPencilButton(_ sender: Any) {
        sketchView.lineWidth = CGFloat(5.0)
        
        thickPencilButton.isEnabled = true
        thinPencilButton.isEnabled = false
        
    }
    
    @IBAction func blackPencilButton(_ sender: Any) {
        sketchView.lineColor = .black
        
        blackPencilButton.isEnabled = false
        redPencilButton.isEnabled = true
        bluePencilButton.isEnabled = true
        
    }
    
    @IBAction func redPencilButton(_ sender: Any) {
        sketchView.lineColor = .red
        
        blackPencilButton.isEnabled = true
        redPencilButton.isEnabled = false
        bluePencilButton.isEnabled = true
    }
    
    @IBAction func bluePencilButton(_ sender: Any) {
        sketchView.lineColor = .blue
        
        blackPencilButton.isEnabled = true
        redPencilButton.isEnabled = true
        bluePencilButton.isEnabled = false
    }
    
    @IBOutlet weak var pencilButton: UIButton!
    
    @IBOutlet weak var eraserButton: UIButton!
    
    @IBOutlet weak var allClearButton: UIButton!
    
    @IBOutlet weak var thickPencilButton: UIButton!
    
    @IBOutlet weak var thinPencilButton: UIButton!
    
    @IBOutlet weak var blackPencilButton: UIButton!

    @IBOutlet weak var redPencilButton: UIButton!

    @IBOutlet weak var bluePencilButton: UIButton!
    
    @IBOutlet weak var canvasView: UIView!
    
    @IBOutlet weak var sketchBaseView: UIView!
    @IBOutlet weak var sketchView: SketchView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        sketchView.drawingPenType = .normal
        sketchView.lineColor = .black
        sketchView.lineWidth = CGFloat(10.0)
        
        pencilButton.isEnabled = false
        blackPencilButton.isEnabled = false
        thickPencilButton.isEnabled = false
        
        canvasView.layer.shadowOpacity = 0.3
        canvasView.layer.shadowRadius = 10
        
        pencilButton.setImage(UIImage.init(named: "pencil"), for: UIControl.State.normal)
        eraserButton.setImage(UIImage.init(named: "eraser"), for: UIControl.State.normal)
        allClearButton.setImage(UIImage.init(named: "allClear"), for: UIControl.State.normal)
        thickPencilButton.setImage(UIImage.init(named: "thick"), for: UIControl.State.normal)
        thinPencilButton.setImage(UIImage.init(named: "thin"), for: UIControl.State.normal)
        blackPencilButton.setImage(UIImage.init(named: "black"), for: UIControl.State.normal)
        redPencilButton.setImage(UIImage.init(named: "red"), for: UIControl.State.normal)
        bluePencilButton.setImage(UIImage.init(named: "blue"), for: UIControl.State.normal)
        
        pencilButton.backgroundColor = UIColor.black
        eraserButton.backgroundColor = UIColor.black
        thickPencilButton.backgroundColor = UIColor.black
        thinPencilButton.backgroundColor = UIColor.black
        blackPencilButton.backgroundColor = UIColor.black
        redPencilButton.backgroundColor = UIColor.black
        bluePencilButton.backgroundColor = UIColor.black
        pencilButton.layer.borderWidth = 1.0
        pencilButton.layer.borderColor = UIColor.black.cgColor
        eraserButton.layer.borderWidth = 1.0
        eraserButton.layer.borderColor = UIColor.black.cgColor
        allClearButton.layer.borderWidth = 1.0
        allClearButton.layer.borderColor = UIColor.black.cgColor
        thickPencilButton.layer.borderWidth = 1.0
        thickPencilButton.layer.borderColor = UIColor.black.cgColor
        thinPencilButton.layer.borderWidth = 1.0
        thinPencilButton.layer.borderColor = UIColor.black.cgColor
        
        
        
        alert = UIAlertController(title: "全消し", message: "今書いている絵を全て消しますか？", preferredStyle: UIAlertController.Style.alert)
        //「続けるボタン」のアラートアクションを作成する。
        let alertAction = UIAlertAction(
            title: "全て消す",
            style: UIAlertAction.Style.destructive,
            handler: { action in
                self.sketchView.clear()
            }
        )
                
        //「キャンセルボタン」のアラートアクションを作成する。
        let alertAction2 = UIAlertAction(
            title: "消さない",
            style: UIAlertAction.Style.cancel,
            handler: nil
        )
        
        //アラートアクションを追加する。
        alert.addAction(alertAction)
        alert.addAction(alertAction2)
        
    }
}

