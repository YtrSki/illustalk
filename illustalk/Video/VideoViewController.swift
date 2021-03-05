//
//  ViewController.swift
//  illustalk
//
//  Created by YutaroSakai on 2020/10/20.
//
//  SkyWayの通信実装の参考；https://github.com/taminif/SkyWaySFUSample
//

import UIKit
import SkyWay
import Sketch

class VideoViewController: UIViewController, UICollectionViewDataSource,
UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var givenRoomName: String! // 前の画面から画面遷移時に渡されるルーム名変数　SkyWayの部屋名として使われる
    var givenHiraganaRoomName: String! // 前の画面から画面遷移時に渡されるひらがな部屋名　ユーザに見せるためだけに使われる

    // SkyWay Configuration Parameter
    let apiKey = "4ef87046-d284-414f-9b6b-4b5ab9d4d961"
    let domain = "localhost"

    let roomNamePrefix = "sfu_video_"
    var ownId: String = ""
    let lock: NSLock = NSLock.init()
    var arrayMediaStreams: NSMutableArray = []
    var arrayVideoViews: NSMutableDictionary = [:]

    var peer: SKWPeer?
    var localStream: SKWMediaStream?
    var sfuRoom: SKWSFURoom?
    
    var sketchImage: UIImage? = nil // 画像化されたイラストを格納しておく変数
    
    var isClosed: Bool = false // 退出ボタンが押された時に自分のセルの映像を削除する

    @IBOutlet weak var sketchViewController: UIView!
    @IBOutlet weak var roomNameLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var endButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backToTopButton: UIButton!
    @IBOutlet weak var sendIllustButton: UIButton!
    @IBOutlet weak var waitingOthersView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        endButton.isHidden = true
        sendIllustButton.isHidden = true
        waitingOthersView.isHidden = true
        
        // ボタンの角を丸くする
        submitButton.layer.cornerRadius = 10
        backToTopButton.layer.cornerRadius = 10
        endButton.layer.cornerRadius = 10
        sendIllustButton.layer.cornerRadius = 10

        // peer connection
        let options: SKWPeerOption = SKWPeerOption.init()
        options.key = apiKey
        options.domain = domain
        // options.debug = .DEBUG_LEVEL_ALL_LOGS
        peer = SKWPeer.init(options: options)

        // peer event handling
        peer?.on(.PEER_EVENT_OPEN, callback: {obj in
            self.ownId = obj as! String

            // create local video
            let constraints: SKWMediaConstraints = SKWMediaConstraints.init()
            constraints.maxWidth = 960
            constraints.maxHeight = 540
            constraints.cameraPosition = SKWCameraPositionEnum.CAMERA_POSITION_FRONT

            SKWNavigator.initialize(self.peer!)
            self.localStream = SKWNavigator.getUserMedia(constraints)
        })

        peer?.on(.PEER_EVENT_CLOSE, callback: {obj in
            self.ownId = ""
            SKWNavigator.terminate()
            self.peer = nil
        })
        
        self.collectionView.reloadData()

        self.roomNameLabel.text = "部屋名：\(self.givenHiraganaRoomName ?? "[部屋名表示エラー(sfuRoom?.on(.ROOM_EVENT_OPEN))]")" // 通話画面に表示するひらがなの部屋名
        print("部屋名：\(self.givenRoomName!)") // デバッグ出力する実際の部屋名
        
        let waitingMessage: UILabel = waitingOthersView.viewWithTag(1) as! UILabel
        waitingMessage.text = "他の参加者を待っています..."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        super.viewDidDisappear(animated)
    }

    deinit {
        localStream = nil
        ownId = ""
        sfuRoom = nil
        peer = nil
    }

    @IBAction func joinRoom(_ sender: Any) {
        // 前の画面から渡された部屋名をSkyWayのコードに渡す
        // 何らかの原因で部屋名が正しく渡されなかった場合は、アラートを表示して前の画面に戻る
        guard let roomName = givenRoomName else {
            print("正しい部屋名がVideoViewControllerに渡されていない")
            presentPopUpMessege("通話を始めることができませんでした。前の画面に戻ります。")
            return
        }

        // join SFU room
        let option = SKWRoomOption.init()
        option.mode = .ROOM_MODE_SFU
        option.stream = self.localStream
        sfuRoom = peer?.joinRoom(withName: roomNamePrefix + roomName, options: option) as? SKWSFURoom

        // room event handling
        // 通話状態が開始された場合
        sfuRoom?.on(.ROOM_EVENT_OPEN, callback: {obj in
            self.submitButton.isHidden = true
            self.endButton.isHidden = false
            self.backToTopButton.isHidden = true // 通話を始める前の「戻る」ボタンを見えなくする
            self.waitingOthersView.isHidden = false // 「他の参加者を待っています」のビューを見せる
        })
        
        sfuRoom?.on(.ROOM_EVENT_CLOSE, callback: {obj in
            self.lock.lock()

            self.arrayMediaStreams.enumerateObjects({obj, _, _ in
                let mediaStream: SKWMediaStream = obj as! SKWMediaStream
                let peerId = mediaStream.peerId!
                // remove other videos
                if let video: SKWVideo = self.arrayVideoViews.object(forKey: peerId) as? SKWVideo {
                    mediaStream.removeVideoRenderer(video, track: 0)
                    video.removeFromSuperview()
                    self.arrayVideoViews.removeObject(forKey: peerId)
                }
            })

            self.arrayMediaStreams.removeAllObjects()
            self.collectionView.reloadData()

            self.lock.unlock()

            // leave SFU room
            self.sfuRoom?.offAll()
            self.sfuRoom = nil
        })
        
        sfuRoom?.on(.ROOM_EVENT_STREAM, callback: {obj in
            let mediaStream: SKWMediaStream = obj as! SKWMediaStream

            self.lock.lock()

            self.waitingOthersView.isHidden = true // 他の参加者が入ってきたら待ち表示を消す
            self.sendIllustButton.isHidden = false // 他の参加者が入ってきたらイラストを送るボタンを表示する
            
            // add videos
            self.arrayMediaStreams.add(mediaStream)
            self.collectionView.reloadData()

            self.lock.unlock()
        })
        
//        // 'ROOM_EVENT_REMOVE_STREAM' is deprecated: Use PEER_LEAVE event instead.
//        sfuRoom?.on(.ROOM_EVENT_REMOVE_STREAM, callback: {obj in
//            let mediaStream: SKWMediaStream = obj as! SKWMediaStream
//            let peerId = mediaStream.peerId!
//
//            self.lock.lock()
//
//            // remove video
//            if let video: SKWVideo = self.arrayVideoViews.object(forKey: peerId) as? SKWVideo {
//                mediaStream.removeVideoRenderer(video, track: 0)
//                video.removeFromSuperview()
//                self.arrayVideoViews.removeObject(forKey: peerId)
//            }
//
//            self.arrayMediaStreams.remove(mediaStream)
//            self.collectionView.reloadData()
//
//            self.lock.unlock()
//        })
        
        sfuRoom?.on(.ROOM_EVENT_PEER_LEAVE, callback: {obj in
            let peerId = obj as! String
            var checkStream: SKWMediaStream? = nil

            self.lock.lock()

            self.arrayMediaStreams.enumerateObjects({obj, _, _ in
                let mediaStream: SKWMediaStream = obj as! SKWMediaStream
                if peerId == mediaStream.peerId {
                    checkStream = mediaStream
                }
            })

            if let checkStream = checkStream {
                // remove video
                if let video: SKWVideo = self.arrayVideoViews.object(forKey: peerId) as? SKWVideo {
                    checkStream.removeVideoRenderer(video, track: 0)
                    video.removeFromSuperview()
                    self.arrayVideoViews.removeObject(forKey: peerId)
                }
                self.arrayMediaStreams.remove(checkStream)
                self.collectionView.reloadData()
            }

            self.lock.unlock()
        })
        
        // MARK: スケッチオブジェクト受信処理
        sfuRoom?.on(.ROOM_EVENT_DATA, callback: {obj in
            let skwRoomDataMessage: SKWRoomDataMessage = obj as! SKWRoomDataMessage
            let receivedNSData: NSData = skwRoomDataMessage.data as! NSData
            let receivedData: Data = Data(referencing: receivedNSData)
            let receivedSketchImage: UIImage
            
            do {
                receivedSketchImage = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(receivedData) as! UIImage
                print(receivedSketchImage)
            }
            catch {
                print("受信後変換失敗")
                self.presentPopUpMessege("誰かからイラストを受け取りましたが、画面に映すことができませんでした。")
                return
            }
            
            let receivedSketchViewController = UIStoryboard(name: "ReceivedSketchViewController", bundle: nil).instantiateViewController(withIdentifier: "receivedSketchViewController") as! ReceivedSketchViewController
            receivedSketchViewController.receivedSketchImage = receivedSketchImage
            receivedSketchViewController.senderPeerId = skwRoomDataMessage.src
            receivedSketchViewController.modalPresentationStyle = .pageSheet
            self.present(receivedSketchViewController, animated: true, completion: nil)
        })
    }

    @IBAction func leaveRoom(_ sender: Any) {
        let popUpLeaveViewController: PopUpLeaveViewController = UIStoryboard(name: "PopUpLeaveViewController", bundle: nil).instantiateViewController(withIdentifier: "popUpLeaveViewController") as! PopUpLeaveViewController // ポップアップ画面のViewControllerをインスタンス化する
        popUpLeaveViewController.modalPresentationStyle = .overFullScreen // 今のビューに重ねるように表示
        popUpLeaveViewController.modalTransitionStyle = .crossDissolve // 画面切り替わりのアニメーションをクロスディゾルブに変更
        present(popUpLeaveViewController, animated: true, completion: nil)
    }
    
    @IBAction func backToTop(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: スケッチオブジェクト送信処理
    // ContainerViewの中のSketchViewControllerにあるsketchViewを取り出して送信
    @IBAction func sendSketchView(_ sender: Any) {
        // ポップアップで確認画面を出す
        if self.sfuRoom == nil { return } // 通話が始まっていなかったら何も起こらないようにする
        let popUpSketchSendViewController: PopUpSketchSendViewController = UIStoryboard(name: "PopUpSketchSendViewController", bundle: nil).instantiateViewController(withIdentifier: "popUpSketchSendViewController") as! PopUpSketchSendViewController // ポップアップ画面のViewControllerをインスタンス化する
        let sketchBaseView: UIView = (self.children[0] as! SketchViewController).sketchBaseView // スケッチビューを取得する
        self.sketchImage = sketchViewToUIImage(sketchBaseView) // スケッチビューを画像化して sketchImage に保存
        popUpSketchSendViewController.sketchImage = sketchImage // ポップアップ画面に渡す
        
        popUpSketchSendViewController.modalPresentationStyle = .overFullScreen // 今のビューに重ねるように表示
        popUpSketchSendViewController.modalTransitionStyle = .crossDissolve // 画面切り替わりのアニメーションをクロスディゾルブに変更
        present(popUpSketchSendViewController, animated: true, completion: nil)
    }
    
    // UIViewをUIImageへ変換
    func sketchViewToUIImage(_ sketchBaseView: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sketchBaseView.bounds.size, true, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        context.setShouldAntialias(false)
        sketchBaseView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let png = image.pngData()!
        let pngImage = UIImage.init(data: png)!
        return pngImage
    }
    
    // 退出するか確認するポップアップ画面で「はい」が選ばれたら実行される
    func doLeaveRoom() {
        // leave SFU room
        self.sfuRoom?.close()
        self.dismiss(animated: true, completion: nil)
    }
    
    // イラストを送信するか確認するポップアップ画面で「送る」が選ばれたら実行される
    // 画像化処理はポップアップ画面呼び出し処理 sendSketchView() で実行済み
    func doSendSketch() {
        let sketchData: NSData
        
        do {
            sketchData = try NSKeyedArchiver.archivedData(withRootObject: self.sketchImage!, requiringSecureCoding: false) as NSData
        }
        catch {
            print("送信前変換失敗")
            presentPopUpMessege("イラストを送れませんでした。もう一度お試しください。")
            return
        }
        
        self.sfuRoom?.send(sketchData)
    }
    
    func presentPopUpMessege(_ messegeText: String) {
        let popUpMessegeViewController = UIStoryboard(name: "PopUpMessegeViewController", bundle: nil).instantiateViewController(withIdentifier: "popUpMessegeViewController") as! PopUpMessegeViewController
        popUpMessegeViewController.messegeText = messegeText
        popUpMessegeViewController.modalPresentationStyle = .overFullScreen
        popUpMessegeViewController.modalTransitionStyle = .crossDissolve
        self.present(popUpMessegeViewController, animated: true, completion: nil)
    }
    
    // CollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayMediaStreams.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        // Configure the cell
        if let view: UIView = cell.viewWithTag(1) {
            switch indexPath.row {
            // 一番左上のセルには自分のカメラ映像を表示する
            case 0:
                let video: SKWVideo! = view.viewWithTag(2) as? SKWVideo
                
                self.localStream?.addVideoRenderer(video, track: 0)
                video!.frame = cell.bounds
                view.addSubview(video!)
                video!.setNeedsLayout()
                break
            // その他のセルには他の参加者のカメラ映像を表示する
            default:
                if let stream: SKWMediaStream = arrayMediaStreams.object(at: indexPath.row - 1) as? SKWMediaStream {
                    let peerId: String = stream.peerId!
                    // add stream
                    var video: SKWVideo? = arrayVideoViews.object(forKey: peerId) as? SKWVideo
                    if video == nil {
                        video = SKWVideo.init(frame: cell.bounds)
                        stream.addVideoRenderer(video!, track: 0)
                        arrayVideoViews.setObject(video!, forKey: peerId as NSCopying)
                    }
                    video!.frame = cell.bounds
                    view.addSubview(video!)
                    video!.setNeedsLayout()
                }
                break
            }
        }
        
        cell.layer.cornerRadius = 5 // 全てのカメラ映像のセルを少し角丸にする

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.bounds.width / 2 - 10, height: self.collectionView.bounds.height / 2 - 10)
    }
}



