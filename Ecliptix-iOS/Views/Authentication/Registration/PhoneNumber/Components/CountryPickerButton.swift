//
//  CountryPicker.swift
//  Ecliptix-iOS-Views
//
//  Created by Oleksandr Melnechenko on 02.06.2025.
//


import SwiftUI

struct CountryPickerButton: View {
    @Binding var selectedCountry: Country
    @Binding var isShowingCountryPicker: Bool
    let countries: [Country]
    
    var body: some View {
        Button(action: {
            isShowingCountryPicker = true
        }) {
            HStack {
                Image(selectedCountry.flag)
                    .resizable()
                    .frame(width: 32, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text(selectedCountry.name)
                    .font(.headline)
                    .foregroundStyle(Color.black)
                
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .sheet(isPresented: $isShowingCountryPicker) {
            CountryPickerView(
                selectedCountry: $selectedCountry,
                countries: countries
            )
        }
    }
}

#Preview {
    struct CountryPickerPreviewWrapper: View {
        @State private var selectedCountry = Country(name: "Ukraine", phoneCode: "+380", flag: "ua")
        @State private var isShowing = false

        var body: some View {
            CountryPickerButton(
                selectedCountry: $selectedCountry,
                isShowingCountryPicker: $isShowing,
                countries: [
                    Country(name: "Ukraine", phoneCode: "+380", flag: "ua"),
                    Country(name: "United States", phoneCode: "+1", flag: "us"),
                    Country(name: "Germany", phoneCode: "+49", flag: "de")
                ]
            )
        }
    }

    return CountryPickerPreviewWrapper()
}

