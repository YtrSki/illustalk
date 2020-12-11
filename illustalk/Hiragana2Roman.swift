//
//  Hiragana2Roman.swift
//  illustalk
//
//  Created by YutaroSakai on 2020/11/19.
//

// ひらがなをローマ字に変換する機能を持つクラス
public class Hiragana2Roman {
    // ひらがな・ローマ字 対応表 (辞書型で定義)
    private let h2rDictionary = [
        "あ":"a",
        "い":"i",
        "う":"u",
        "え":"e",
        "お":"o",

        "か":"ka",
        "き":"ki",
        "く":"ku",
        "け":"ke",
        "こ":"ko",

        "さ":"sa",
        "し":"si",
        "す":"su",
        "せ":"se",
        "そ":"so",
        
        "た":"ta",
        "ち":"ti",
        "つ":"tu",
        "て":"te",
        "と":"to",

        "な":"na",
        "に":"ni",
        "ぬ":"nu",
        "ね":"ne",
        "の":"no",

        "は":"ha",
        "ひ":"hi",
        "ふ":"hu",
        "へ":"he",
        "ほ":"ho",

        "ま":"ma",
        "み":"mi",
        "む":"mu",
        "め":"me",
        "も":"mo",

        "や":"ya",
        "ゆ":"yu",
        "よ":"yo",

        "ら":"ra",
        "り":"ri",
        "る":"ru",
        "れ":"re",
        "ろ":"ro",

        "わ":"wa",
        "を":"wo",
        "ん":"nn",

        "が":"ga",
        "ぎ":"gi",
        "ぐ":"gu",
        "げ":"ge",
        "ご":"go",

        "ざ":"za",
        "じ":"zi",
        "ず":"zu",
        "ぜ":"ze",
        "ぞ":"zo",

        "だ":"da",
        "ぢ":"di",
        "づ":"du",
        "で":"de",
        "ど":"do",

        "ば":"ba",
        "び":"bi",
        "ぶ":"bu",
        "べ":"be",
        "ぼ":"bo",

        "ぱ":"pa",
        "ぴ":"pi",
        "ぷ":"pu",
        "ぺ":"pe",
        "ぽ":"po",
        
        "ゃ":"xya",
        "ゅ":"xyu",
        "ょ":"xyo",

        "ー":"-",
        "っ":"xtu"
    ]
    
    // ひらがなで入力された部屋名をアルファベットに変換する、入力内容が正しくなければnilが返される
    public func hiragana2Roman(_ hiragana: String) -> String? {
        let hiragana: String = hiragana
        if hiragana == "" { // 何も入力されていない状態で変換が押されたら処理を中止
            print("ひらがなが入力されていません。")
            return nil
        }
        var roman: String = "" // 変換後のローマ字文字列変数を用意
        
        for i in 0...hiragana.count - 1 { // ひらがなの文字数だけ繰り返す
            let index = hiragana.index(hiragana.startIndex, offsetBy: i) // ひらがな文字列の最初の文字からi文字目という番号を取り出す
            let h: String = String(hiragana[index]) // その番号に位置しているひらがな1文字を取り出す
            if h2rDictionary[h] == nil { // もし取り出した文字がひらがなでなかった場合（対応表の辞書に含まれていない場合）変換できないので処理を中止する
                print("ひらがなではない文字が入力されています。使える文字はひらがなのみです。")
                return nil
            }
            roman += h2rDictionary[h]! // 対応表の辞書からローマ字表記を取り出して書き加えていく
        }
        
        return roman
    }
    
}
