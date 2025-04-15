import SwiftUI

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var weatherViewModel: WeatherViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a city", text: $weatherViewModel.searchText)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                List(weatherViewModel.searchResults) { city in
                    Button(action: {
                        weatherViewModel.fetchWeather(for: city)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(city.fullName)
                    }
                }
                .listStyle(PlainListStyle())
                
                if weatherViewModel.searchResults.isEmpty && !weatherViewModel.searchText.isEmpty {
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                }
            }
            .navigationTitle("Search City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
