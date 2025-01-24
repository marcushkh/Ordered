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
    
    let embedding = NLEmbedding.sentenceEmbedding(for: .english)!
    
    init(){
//        load()
//        toEmbed()
//        allEmojiEmbedded = loadFromJSON(fileName: "emoji_embeddings.json") ?? []
    }
    
    static func create() async -> DataLoader {
        let loader = DataLoader()
        await loader.load()
        await loader.toEmbed()
        return loader
    }
    
    func load() async {
        if let fileLocation = Bundle.main.url(forResource: "full_emoji", withExtension: "json") {
            do{
                let data = try Data(contentsOf: fileLocation)
                let jsonDecoder = JSONDecoder()
                let dataFromJson = try jsonDecoder.decode([Emoji].self, from: data)
                
                DispatchQueue.main.async {
                    self.allEmoji = dataFromJson
                }
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
    }
    
    func toEmbed() async {
        
        var allEmojiEmbeddedArr: [[[Double]]] = []
        for i in allEmoji{
            //turn description & keywords into a string and embed it
            var arr: [[Double]] = []
            
            for j in i.keywords{
                if let embedded = embedding.vector(for: j){
                    arr.append(embedded)
                }
            }
            if let embedded = embedding.vector(for: i.description){
                arr.append(embedded)
            }
            allEmojiEmbeddedArr.append(arr)
        }
        saveToJSON(allEmojiEmbeddedArr, fileName: "emoji_embeddings.json")
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
    
    func getSuggestion(_ str: String, top_n: Int = 5, penalty: Double = 1.0) async -> String {
        if let v1 = embedding.vector(for: str){
            var allMark: [Double] = []
            
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
            
            let list = getBestIndex(top_n: top_n, array: allMark)
            return list.map { String(allEmoji[$0].emoji) }.joined(separator: "")
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
