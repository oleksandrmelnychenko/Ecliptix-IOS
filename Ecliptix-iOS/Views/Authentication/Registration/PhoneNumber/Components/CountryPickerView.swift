//
//  CountryPickerView.swift
//  Protocol
//
//  Created by Oleksandr Melnechenko on 21.05.2025.
//

import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountry: Country
    let countries: [Country]
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            CountryList(
                countries: countries,
                searchText: $searchText,
                selectedCountry: $selectedCountry,
                dismiss: dismiss
            )
            

//            CountryListByName(
//                countries: countries,
//                searchText: $searchText,
//                selectedCountry: $selectedCountry,
//                dismiss: dismiss
//            )
        }
    }
}




struct CountryListByName: View {
    let countries: [Country]
    @Binding var searchText: String
    @Binding var selectedCountry: Country
    let dismiss: DismissAction
    
    private var filteredCountries: [Country] {
        countries.filter {
            searchText.isEmpty ||
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.phoneCode.contains(searchText)
        }
    }
    
    private var groupedCountries: [String: [Country]] {
        Dictionary(grouping: filteredCountries) { country in
            String(country.name.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        List {
            ForEach(groupedCountries.keys.sorted(), id: \.self) { letter in
                Section(header: Text(letter)) {
                    ForEach(groupedCountries[letter]!, id: \.self) { country in
                        Button(action: {
                            selectedCountry = country
                            dismiss()
                        }) {
                            HStack {
                                Image(country.flag)
                                    .resizable()
                                    .frame(width: 32, height: 24)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .accessibilityHidden(true)
                                
                                Text(country.name)
                                    .foregroundStyle(Color.black)
                                
                                Spacer()
                                
                                Text(country.phoneCode)
                                    .foregroundStyle(Color.black)
                                    .accessibilityLabel("Phone code \(country.phoneCode)")
                                
                                if country == selectedCountry {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.black)
                                        .accessibilityLabel("Selected")
                                }
                            }
                            .accessibilityLabel("\(country.name), \(country.phoneCode)")
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationTitle("Select Country")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    struct CountryPickerViewPreviewWrapper: View {
        @State private var selected = Country(name: "Ukraine", phoneCode: "+380", flag: "ua")

        var body: some View {
            CountryPickerView(
                selectedCountry: $selected,
                countries: [
                    Country(name: "Ukraine", phoneCode: "+380", flag: "ua"),
                    Country(name: "United States", phoneCode: "+1", flag: "us"),
                    Country(name: "Australia", phoneCode: "+61", flag: "au")
                ]
            )
        }
    }
    
    return CountryPickerViewPreviewWrapper()
}
