//
//  ViewController.swift
//  illustalk
//
//  Created by YutaroSakai on 2020/10/09.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBAction func openTalkScreenButtonAction(_ sender: Any) {
        if roomNameTextField.hasText { //テキストフィールドに文字が入っていれば実行
            let hiraganaRoomName = roomNameTextField.text // テキストフィールドから文字列を取り出し
            guard let romanRoomName = Hiragana2Roman().hiragana2Roman(hiraganaRoomName!) else { // ひらがな→ローマ字変換クラスをインスタンス化して変換
                descriptionLabel.text = "部屋の名前が正しく入力されていません！\n部屋の名前をひらがなのみで入力してください"
                descriptionLabel.textColor = UIColor(red: 0.7, green: 0, blue: 0, alpha: 1)
                return
            }
            let talkScreen = UIStoryboard(name: "VideoViewController", bundle: nil).instantiateViewController(withIdentifier: "videoViewController") as! VideoViewController //通話画面のインスタンスを生成
            talkScreen.givenRoomName = romanRoomName //通話画面に入力されたローマ字の部屋名を渡す
            talkScreen.givenHiraganaRoomName = hiraganaRoomName //通話画面に入力されたひらがなの部屋名を渡す
            talkScreen.modalPresentationStyle = .fullScreen //通話画面をフルスクリーンで表示するようにする
            talkScreen.modalTransitionStyle = .flipHorizontal //画面遷移のアニメーションを回転式にする
            present(talkScreen, animated: true, completion: nil) //画面遷移を実行
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}

