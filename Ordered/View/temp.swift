//
//  temp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 15/1/2025.
//

import SwiftUI
import PythonKit

struct temp: View {
    @State private var userInput: String = ""
    @State private var recommendations: [EmojiRecommendation] = []

    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter text for emoji suggestions", text: $userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Get Recommendations") {
                fetchRecommendations(for: userInput)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            List(recommendations, id: \.emoji) { recommendation in
                HStack {
                    Text(recommendation.emoji)
                        .font(.largeTitle)
                    Text(recommendation.description)
                        .font(.body)
                }
            }
        }
        .padding()
    }

    func fetchRecommendations(for input: String) {
        let Python = Python.import("recommend")  // Import the Python script
        let result = Python.recommend_emojis(input, top_n: 5)

        // Convert Python list of dictionaries to Swift structs
        recommendations = result.map { item in
            EmojiRecommendation(
                emoji: String(item["emoji"]) ?? "",
                description: String(item["description"]) ?? ""
            )
        }
    }
}

struct EmojiRecommendation: Identifiable {
    let id = UUID()
    let emoji: String
    let description: String
}

#Preview {
    temp()
}
