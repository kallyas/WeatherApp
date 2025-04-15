import Foundation
import Combine

class SearchViewModel: ObservableObject {
    private let searchCityUseCase: SearchCityUseCaseProtocol
    
    @Published var searchText = ""
    @Published var searchResults: [City] = []
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(searchCityUseCase: SearchCityUseCaseProtocol) {
        self.searchCityUseCase = searchCityUseCase
        
        // Setup search debounce
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                guard let self = self, !searchTerm.isEmpty, searchTerm.count >= 2 else {
                    self?.searchResults = []
                    return
                }
                self.searchCity(query: searchTerm)
            }
            .store(in: &cancellables)
    }
    
    func searchCity(query: String) {
        isSearching = true
        searchCityUseCase.execute(query: query) { [weak self] cities in
            self?.searchResults = cities
            self?.isSearching = false
        }
    }
}
