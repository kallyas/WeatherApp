import SwiftUI

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var weatherViewModel: WeatherViewModel
    @State private var showingNoResults = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search for a city", text: $weatherViewModel.searchText)
                        .autocorrectionDisabled(true)
                    
                    if !weatherViewModel.searchText.isEmpty {
                        Button(action: {
                            weatherViewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Search results
                if weatherViewModel.isLoading {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if weatherViewModel.searchResults.isEmpty && !weatherViewModel.searchText.isEmpty && weatherViewModel.searchText.count >= 2 {
                    Spacer()
                    ContentUnavailableView(
                        "No Cities Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search term")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(weatherViewModel.searchResults) { city in
                            Button(action: {
                                weatherViewModel.fetchWeather(for: city)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(city.name)
                                            .font(.headline)
                                        Text(city.country)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if weatherViewModel.searchText.isEmpty {
                    // Show hint when search field is empty
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("Search for a city to see the weather")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
