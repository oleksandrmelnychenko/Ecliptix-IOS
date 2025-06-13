//
//  CountryList.swift
//  Ecliptix-iOS
//
//  Created by Oleksandr Melnechenko on 13.06.2025.
//


import SwiftUI

struct CountryList: View {
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
    
    var body: some View {
        List {
            ForEach(filteredCountries, id: \.self) { country in
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
        .searchable(text: $searchText)
        .navigationTitle(Strings.PhoneNumber.countryPickerTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(Strings.PhoneNumber.countryPickerCancelButtonTitle) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    struct CountryListPreviewWrapper: View {
        @State private var searchText: String = ""
        @State private var selectedCountry = Country(name: "Ukraine", phoneCode: "+380", flag: "ua")
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            CountryList(
                countries: [
                    Country(name: "Ukraine", phoneCode: "+380", flag: "ua"),
                    Country(name: "United States", phoneCode: "+1", flag: "us"),
                    Country(name: "Germany", phoneCode: "+49", flag: "de")
                ],
                searchText: $searchText,
                selectedCountry: $selectedCountry,
                dismiss: dismiss
            )
        }
    }

    return CountryListPreviewWrapper()
}

