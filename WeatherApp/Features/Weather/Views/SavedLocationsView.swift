//
//  SavedLocationsView.swift
//  WeatherApp
//
//  Created by Tumuhirwe Iden on 22/04/2025.
//


import SwiftUI
import CoreLocation

struct SavedLocationsView: View {
    @ObservedObject var weatherViewModel: WeatherViewModel
    let locationsUseCase: ManageLocationsUseCaseProtocol
    @State private var showingDeleteAlert = false
    @State private var locationToDelete: SavedLocation?
    @State private var isEditMode: EditMode = .inactive
    @EnvironmentObject var themeManager: ThemeManager
    
    init(locationsUseCase: ManageLocationsUseCaseProtocol, weatherViewModel: WeatherViewModel) {
        self.locationsUseCase = locationsUseCase
        self.weatherViewModel = weatherViewModel
    }
    
    var body: some View {
        NavigationView {
            List {
                // Favorites Section
                Section(header: Text("Favorite Locations")) {
                    if locationsUseCase.getFavoriteLocations().isEmpty {
                        HStack {
                            Spacer()
                            Text("No favorite locations")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ForEach(locationsUseCase.getFavoriteLocations(), id: \.id) { location in
                            locationRow(location)
                        }
                        .onDelete(perform: { indexSet in
                            deleteFavoriteLocations(at: indexSet)
                        })
                    }
                }
                
                // Recent Locations Section
                Section(header: 
                    HStack {
                        Text("Recent Locations")
                        Spacer()
                        if !locationsUseCase.getRecentLocations().isEmpty {
                            Button("Clear All") {
                                showingDeleteAlert = true
                            }
                            .foregroundColor(themeManager.accentColor)
                        }
                    }
                ) {
                    if locationsUseCase.getRecentLocations().isEmpty {
                        HStack {
                            Spacer()
                            Text("No recent locations")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ForEach(locationsUseCase.getRecentLocations(), id: \.id) { location in
                            locationRow(location)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Saved Locations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .environment(\.editMode, $isEditMode)
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Clear Recent Locations"),
                    message: Text("Are you sure you want to clear all recent locations?"),
                    primaryButton: .destructive(Text("Clear All")) {
                        locationsUseCase.clearRecentLocations()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func locationRow(_ location: SavedLocation) -> some View {
        Button(action: {
            if isEditMode == .inactive {
                selectLocation(location)
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(location.name)
                        .font(.headline)
                    Text(location.country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add to favorites button
                if !isFavorite(location) {
                    Button(action: {
                        addToFavorites(location)
                    }) {
                        Image(systemName: "star")
                            .foregroundColor(themeManager.accentColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .opacity(isEditMode == .inactive ? 1 : 0)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func selectLocation(_ location: SavedLocation) {
        let city = City(
            name: location.name,
            country: location.country,
            coordinates: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
        )
        weatherViewModel.fetchWeather(for: city)
    }
    
    private func addToFavorites(_ location: SavedLocation) {
        locationsUseCase.addToFavorites(location)
    }
    
    private func isFavorite(_ location: SavedLocation) -> Bool {
        return locationsUseCase.getFavoriteLocations().contains { $0.id == location.id }
    }
    
    private func deleteFavoriteLocations(at offsets: IndexSet) {
        let favorites = locationsUseCase.getFavoriteLocations()
        offsets.forEach { index in
            let location = favorites[index]
            locationsUseCase.removeFromFavorites(location.id)
        }
    }
}