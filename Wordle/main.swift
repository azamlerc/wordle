//
//  main.swift
//  Wordle
//
//  Created by Andrew Zamler-Carhart on 11/6/22.
//

import Foundation

let runToday = true
let runStats = false
let justA = false
let justUsed = true
let justHard = false

let useLetterFrequency = true
let skipUsed = true

let printGuesses = false

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

extension Character {
    var unicode: UnicodeScalar {
        get {
            let s = String(self).unicodeScalars
            return UnicodeScalar(Int(s[s.startIndex].value))!
        }
    }
}

class Word {
    var value: String
    var set: CharacterSet
    var used = false
    var score = 0.0
    
    init(value: String) {
        self.value = value
        self.set = CharacterSet(charactersIn: value)
    }

    var description: String {
        return self.value
    }

    func setScore(_ includedLetters: CharacterSet) {
        if useLetterFrequency {
            score = 0.0
            var counted = CharacterSet()
            // var skipped = CharacterSet()
            for i in 0...4 {
                let val = value[i].unicode
                if (!includedLetters.contains(val) && !counted.contains(val)) /*|| skipped.contains(val)*/ {
                    score += letterFrequencies[value[i]]!
                    counted.insert(val)
                } else {
                    // skipped.insert(val)
                }
            }
        }
    }
}

let allWords = allowedData
    .map { $0.components(separatedBy: " ")}
    .flatMap { $0 }
    .map { Word(value: $0) }

class Wordle {
    var answer: Word
    var tries = 0
    
    var yellowLetters = [CharacterSet]()
    var greenLetters = [CharacterSet]()
    var includedLetters = CharacterSet()
    var excludedLetters = CharacterSet()
    
    init(answer: String) {
        self.answer = Word(value: answer)
        
        for _ in 0...4 {
            yellowLetters.append(CharacterSet())
            greenLetters.append(CharacterSet())
        }
    }
    
    func addConstraints(_ constraints: [String:String]) {
        for (guess, resultCode) in constraints {
            for i in 0...4 {
                let letter = guess[i]
                let number = resultCode[i]
                
                if number == "0" {
                    excludedLetters.insert(letter.unicode)
                } else if number == "1" {
                    includedLetters.insert(letter.unicode)
                    yellowLetters[i].insert(letter.unicode)
                } else if number == "2" {
                    includedLetters.insert(letter.unicode)
                    greenLetters[i].insert(letter.unicode)
                }
            }
        }
    }
    
    func possibleWords() -> [Word] {
        return allWords.filter { word in
            if skipUsed && word.used {
                return false
            }
            
            if tries == 0 {
                word.setScore(includedLetters)
                return true
            }
            
            if !includedLetters.isSubset(of: word.set) {
                return false
            }
            
            if !excludedLetters.intersection(word.set).isEmpty {
                return false
            }
            
            for i in 0...4 {
                let letter = word.value[i]
                
                if yellowLetters[i].contains(letter.unicode) {
                    return false
                }
                
                if !greenLetters[i].isEmpty && !greenLetters[i].contains(letter.unicode) {
                    return false
                }
            }
            
            word.setScore(includedLetters)
            return true
        }
    }
    
    func guess(_ guess: String) -> String {
        var resultCode = ""
        
        for i in 0...4 {
            if answer.value[i] == guess[i] {
                resultCode += "2"
            } else if answer.set.contains(guess[i].unicode) {
                resultCode += "1"
            } else {
                resultCode += "0"
            }
        }

        tries += 1

        addConstraints([guess:resultCode])
        // print("\(tries) \(guess): \(resultCode)")
        
        return resultCode
    }
    
    func play() -> Int {
        var result = "00000"
        var remaining = possibleWords()
        while remaining.count > 0 && tries < 6 {
            if useLetterFrequency {
                remaining.sort { $0.score > $1.score }
            }
            
            let best = remaining[0]
            result = guess(best.value)

            if (printGuesses) {
                let remainingSlice = remaining.count > 15 ? Array(remaining[0...14]) : remaining
                print("\(tries) \(best.value): \(result) - \(remaining.count) \(remainingSlice.map { $0.value } )")
            }

            remaining = possibleWords()
            
            if (result == "22222") {
                // print("Whew!")
                best.used = true
                return tries
            }

            
        }

        if (remaining.count == 0) {
            // print("Stumped!")
            return -1
        } else {
            // print("Rats!")
            return 7
        }
    }
}

// 2309: ["atone", "irate", "onset", "stone", "haste", "tenor", "hater", "heart", "stare", "earth", "ethos", "those", "stein", "other", "store"]

if runToday {
    let wordle = Wordle(answer: "goose")
    wordle.tries = -1

    var constraints: [String:String] = [:]
    for argument in CommandLine.arguments {
        let keyValue = argument.split(separator: ":")
        if keyValue.count == 2 {
            let key = String(keyValue[0])
            let value = String(keyValue[1])
            constraints[key] = value
        }
    }
    wordle.addConstraints(constraints)
    var remaining = wordle.possibleWords()
    remaining.sort { $0.score > $1.score }
    let remainingSlice = remaining.count > 15 ? Array(remaining[0...14]) : remaining
    print("\(remaining.count): \(remainingSlice.map { $0.value } )")
}

if runStats {
    var stats = [-1: 0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0]
    var testWords = allWords
    if justA {
        testWords = testWords.filter { $0.value.hasPrefix("a") }
    } else if justUsed {
        testWords = usedWords.map { Word(value: $0) }
    } else if justHard {
        testWords = hardWords.map { Word(value: $0) }
    }

    for word in testWords {
        let wordle = Wordle(answer: word.value)
        let result = wordle.play()
        print("\(word.value): \(result)")
        stats[result] = stats[result]! + 1
    }

    for i in 1...6 {
        print("\(i): \(stats[i]!)")
    }
    print("X: \(stats[7]!)")
}

