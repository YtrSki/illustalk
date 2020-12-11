//
//  ViewController.swift
//  illustalk
//
//  Created by YutaroSakai on 2020/10/20.
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        localStream = nil
        ownId = ""
        sfuRoom = nil
        peer = nil
    }

    @IBAction func joinRoom(_ sender: Any) {
//        guard let roomName = roomName.text, roomName != "" else {
//            return
//        }
//        self.roomName.resignFirstResponder()
        
        let roomName = givenRoomName // 前の画面から渡された部屋名をSkyWayのコードに渡す

        // join SFU room
        let option = SKWRoomOption.init()
        option.mode = .ROOM_MODE_SFU
        option.stream = self.localStream
        sfuRoom = peer?.joinRoom(withName: roomNamePrefix + roomName!, options: option) as? SKWSFURoom

        // room event handling
        sfuRoom?.on(.ROOM_EVENT_OPEN, callback: {obj in
//            ↓ viewDidLoad()に記載
//            self.roomNameLabel.text = "部屋名：" + ((obj as? String)?.replacingOccurrences(of: self.roomNamePrefix, with: ""))!
//            self.roomNameLabel.text = "部屋名：\(self.givenHiraganaRoomName ?? "[部屋名表示エラー(sfuRoom?.on(.ROOM_EVENT_OPEN))]")" // 通話画面に表示するひらがなの部屋名
//            print("部屋名：" + ((obj as? String)?.replacingOccurrences(of: self.roomNamePrefix, with: ""))!) // デバッグ出力する実際の部屋名
            self.submitButton.isHidden = true
            self.endButton.isHidden = false
            self.sendIllustButton.isHidden = false
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
            
            // add videos
            self.arrayMediaStreams.add(mediaStream)
            self.collectionView.reloadData()

            self.lock.unlock()
        })

        sfuRoom?.on(.ROOM_EVENT_REMOVE_STREAM, callback: {obj in
            let mediaStream: SKWMediaStream = obj as! SKWMediaStream
            let peerId = mediaStream.peerId!

            self.lock.lock()

            // remove video
            if let video: SKWVideo = self.arrayVideoViews.object(forKey: peerId) as? SKWVideo {
                mediaStream.removeVideoRenderer(video, track: 0)
                video.removeFromSuperview()
                self.arrayVideoViews.removeObject(forKey: peerId)
            }

            self.arrayMediaStreams.remove(mediaStream)
            self.collectionView.reloadData()

            self.lock.unlock()
        })

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
        
        // MARK: スケッチオブジェクト受信処理？
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
                return
            }
            
            let receivedSketchViewController = UIStoryboard(name: "ReceivedSketchViewController", bundle: nil).instantiateViewController(withIdentifier: "receivedSketchViewController") as! ReceivedSketchViewController
            receivedSketchViewController.receivedSketchImage = receivedSketchImage
            receivedSketchViewController.senderPeerId = skwRoomDataMessage.src
            receivedSketchViewController.modalPresentationStyle = .pageSheet
            self.present(receivedSketchViewController, animated: true, completion: nil)
            
/*          SketchView型のデータの送受信は成功したが、これを映すことが出来ない
            送信者のSketchViewの見た目が見られるようにすればいいので、SketchView型で送受信するのではなく、画像に変換してから送受信してみることにする
            
            let sketchViewController: SketchViewController = self.children[0] as! SketchViewController
            sketchViewController.sketchView = receivedSketchView
            
            let receivedSketchViewController = UIStoryboard(name: "ReceivedSketchViewController", bundle: nil).instantiateViewController(withIdentifier: "receivedSketchViewController") as! ReceivedSketchViewController
            receivedSketchViewController.receivedSketchView = receivedSketchView
            self.present(receivedSketchViewController, animated: true, completion: nil)
 */
        })
    }

    @IBAction func leaveRoom(_ sender: Any) {
        guard let sfuRoom = self.sfuRoom else {
            return
        }
        let alert = UIAlertController(title: "通話をやめる", message: "通話をやめてもよろしいですか？", preferredStyle: UIAlertController.Style.alert)
        let alertAction = UIAlertAction(
            title: "はい",
            style: UIAlertAction.Style.destructive,
            handler: { action in
                // leave SFU room
                sfuRoom.close()
                self.dismiss(animated: true, completion: nil)
            }
        )
        let alertAction2 = UIAlertAction(
            title: "いいえ",
            style: UIAlertAction.Style.cancel,
            handler: nil
        )
        //アラートアクションを追加する
        alert.addAction(alertAction)
        alert.addAction(alertAction2)
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func backToTop(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: スケッチオブジェクト送信処理
    // ContainerViewの中のSketchViewControllerにあるsketchViewを取り出して送信
    @IBAction func sendSketchView(_ sender: Any) {
        if self.sfuRoom == nil { return } // 通話始まってなかったらとりあえず何も起こらないようにする
        let sketchBaseView: UIView = (self.children[0] as! SketchViewController).sketchBaseView
        let sketchImage: UIImage = sketchViewToUIImage(sketchBaseView)
        let sketchData: NSData
        
        do {
            sketchData = try NSKeyedArchiver.archivedData(withRootObject: sketchImage, requiringSecureCoding: false) as NSData
        }
        catch {
            print("送信前変換失敗")
            return
        }
        
        print(self.sfuRoom?.send(sketchData) ?? "送信失敗")
    }
    
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
            case 0:
                let video: SKWVideo! = view.viewWithTag(2) as? SKWVideo
                
                self.localStream?.addVideoRenderer(video, track: 0)
                video!.frame = cell.bounds
                view.addSubview(video!)
                video!.setNeedsLayout()
                break
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


