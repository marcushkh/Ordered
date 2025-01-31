//
//  Emoji.swift
//  EmojiRecommender
//
//  Created by Kai Hin Hung on 19/1/2025.
//

// Credit:https://www.youtube.com/watch?v=9tkoD0fSxmU&ab_channel=AjayGandecha

import NaturalLanguage
import SwiftUI

struct Emoji : Codable{
    var emoji: String
    var description: String
    var keywords: [String]
}

public class DataLoader{
    @Published var allEmoji = [Emoji]()
    @Published var allEmojiEmbedded: [[[Double]]] = []
    
    @Published var personalizedEmojiList = [Emoji]()
    @Published var personalizedEmojiEmbedded: [[Double]] = []
    
    
    init(){
        load()
    }
    
    func load() {
        if let fileLocation = Bundle.main.url(forResource: "full_emoji", withExtension: "json") {
            do{
                let data = try Data(contentsOf: fileLocation)
                let jsonDecoder = JSONDecoder()
                let dataFromJson = try jsonDecoder.decode([Emoji].self, from: data)
                
                self.allEmoji = dataFromJson
            }
            catch{
                print(error)
            }
        }
        
        if let fileLocation = Bundle.main.url(forResource: "emoji_embeddings", withExtension: "json") {
            do{
                let data = try Data(contentsOf: fileLocation)
                let jsonDecoder = JSONDecoder()
                self.allEmojiEmbedded = try jsonDecoder.decode([[[Double]]].self, from: data)
            }
            catch{
                print(error)
            }
        }
        
        let listURL = self.getDocumentsDirectory().appendingPathComponent("personalizedEmojiList")
        
        do {
            let jsonData = try Data(contentsOf: listURL)
            let loadedData = try JSONDecoder().decode([Emoji].self, from: jsonData)
            self.personalizedEmojiList = loadedData
        } catch {
            print("Error loading JSON: \(error)")
        }
        
        let EmbedURL = self.getDocumentsDirectory().appendingPathComponent("personalizedEmojiEmbedded")
        
        do {
            let jsonData = try Data(contentsOf: EmbedURL)
            let loadedData = try JSONDecoder().decode([[Double]].self, from: jsonData)
            self.personalizedEmojiEmbedded = loadedData
        } catch {
            print("Error loading JSON: \(error)")
        }
        
    }

    
    func toEmbed() {
        
        var allEmojiEmbeddedArr: [[[Double]]] = []
        for i in allEmoji{
            //turn description & keywords into a string and embed it
            var arr: [[Double]] = []
            for j in i.keywords{
                if let embedded = NLEmbedding.sentenceEmbedding(for: .english)?.vector(for: j){
                    arr.append(embedded)
                }
            }
            if let embedded = NLEmbedding.sentenceEmbedding(for: .english)?.vector(for: i.description){
                arr.append(embedded)
            }
            allEmojiEmbeddedArr.append(arr)
        }
        saveToJSON(allEmojiEmbeddedArr, fileName: "emoji_embeddings.json")
    }
    
    func learn(emoji: String, description: String){
        var e = Emoji(emoji: emoji, description: description, keywords: [])
        let personalizedEmojiListURL = getDocumentsDirectory().appendingPathComponent("personalizedEmojiList")
        let personalizedEmojiEmbeddedURL = getDocumentsDirectory().appendingPathComponent("personalizedEmojiEmbedded")
        
        personalizedEmojiList.append(e)
        personalizedEmojiEmbedded.append(NLEmbedding.sentenceEmbedding(for: .english)?.vector(for: description) ?? [])
        
        do {
            let jsonData = try JSONEncoder().encode(personalizedEmojiList)
            try jsonData.write(to: personalizedEmojiListURL, options: .atomic)
            print("Successfully saved personalizedEmojiList to \(personalizedEmojiListURL)")
        } catch {
            print("Error saving personalizedEmojiList: \(error)")
        }
        
        do {
            let jsonData = try JSONEncoder().encode(personalizedEmojiEmbedded)
            try jsonData.write(to: personalizedEmojiEmbeddedURL, options: .atomic)
            print("Data saved to \(personalizedEmojiEmbeddedURL)")
        } catch {
            print("Error saving JSON: \(error)")
        }
    }
    
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func saveToJSON(_ data: [[[Double]]], fileName: String) {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: fileURL, options: .atomic)
            print("Data saved to \(fileURL)")
        } catch {
            print("Error saving JSON: \(error)")
        }
    }
    
    // Load data from JSON file
    func loadFromJSON(fileName: String) -> [[[Double]]]? {
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let loadedData = try JSONDecoder().decode([[[Double]]].self, from: jsonData)
            return loadedData
        } catch {
            print("Error loading JSON: \(error)")
            return nil
        }
    }
    
    func getSuggestion(_ str: String, top_n: Int = 1, penalty: Double = 1.0) async -> String {
        
        if let v1 = NLEmbedding.sentenceEmbedding(for: .english)?.vector(for: str){
            var allMark: [Double] = []
            var pMark: [Double] = []
            
            for i in allEmojiEmbedded{
                var thisEmojiSimilarity: [Double] = []
                var mark: Double = 0
                for j in i{
                    thisEmojiSimilarity.append(cosineSimilarity(v1, j))
                }
                thisEmojiSimilarity.sort()
                
                for j in 1...3 {
                    if !thisEmojiSimilarity.isEmpty{
                        mark += thisEmojiSimilarity.last!/Double(j)
                        thisEmojiSimilarity.removeLast()
                    }
                }
                allMark.append(mark)
            }
            for i in personalizedEmojiEmbedded{
                var mark: Double = 0
                mark = cosineSimilarity(v1, i)
                mark *= 1.84
                pMark.append(mark)
            }
            
            let list = getBestIndex(top_n: top_n, array: allMark)
            let pList = getBestIndex(top_n: top_n, array: pMark)
            
            if pMark.isEmpty {
                return allEmoji[list[0]].emoji
            }
            if allMark[list[0]] > pMark[pList[0]] {
                return allEmoji[list[0]].emoji
            }
            else{
                return personalizedEmojiList[pList[0]].emoji
            }
        }
        
        return "💡"
    }
    
    func cosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        let dotProduct = zip(vec1, vec2).reduce(0) { $0 + $1.0 * $1.1 }
        let magnitude1 = sqrt(vec1.reduce(0) { $0 + $1 * $1 })
        let magnitude2 = sqrt(vec2.reduce(0) { $0 + $1 * $1 })
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    func getBestIndex(top_n: Int, array: [Double]) -> [Int]{
        let indexedArray = array.enumerated().map { (index, value) in
            (index, value)
        }
        let sortedArray = indexedArray.sorted { $0.1 > $1.1 }
        let topIndices = sortedArray.prefix(top_n).map { $0.0 }
        return topIndices
    }
}
