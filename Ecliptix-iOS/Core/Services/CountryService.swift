//
//  CountryLoader.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 22.05.2025.
//

import Foundation

class CountryService: ObservableObject {
    @Published var countries: [Country] = []

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json") else {
            debugPrint("countries.json not found")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Country].self, from: data)
            countries = decoded
        } catch {
            debugPrint("Failed to decode countries: \(error)")
        }
    }
}
