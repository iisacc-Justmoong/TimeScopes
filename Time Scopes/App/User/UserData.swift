//
//  UserProfile.swift
//  Chrono
//
//  Created by 윤무영 on 11/8/24.
//

import Foundation
import Combine

class UserData: ObservableObject {
    
    @Published var name: String = ""
    @Published var birthday: Date = Date() {
        didSet {
            setAge()
            calculateDeathAge()
        }
    }
    @Published var deathDate: Date = Date() {
        didSet {
            calculateDeathAge()
        }
    }
    @Published var age: Int = 0
    @Published var deathAge: Int = 80
    @Published var sex: String = "Male"
    
    private let userDefaultsKey = "UserData"
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.loadFromUserDefaults()
        configureDateObservers()
        setAge()
        calculateDeathAge()
    }
    
    private func calculateDeathAge() {
        let calculatedDeathAge = DateUtility.calendar.dateComponents([.year], from: birthday, to: deathDate).year ?? 0
        self.deathAge = calculatedDeathAge
    }
    
    func setAge() {
        let calculatedAge = DateUtility.calendar.dateComponents([.year], from: birthday, to: DateUtility.now()).year ?? 0
        self.age = calculatedAge
    }

    private func configureDateObservers() {
        NotificationCenter.default.publisher(for: .NSCalendarDayChanged)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.setAge()
                self?.calculateDeathAge()
            }
            .store(in: &cancellables)
    }
    
    
    
    
    
    
    // MARK: - UserDefaults
    func saveToUserDefaults() {
        let encoder = JSONEncoder()
        let snapshot = UserDataSnapshot(
            name: self.name,
            birthday: self.birthday,
            deathDate: self.deathDate,
            age: self.age,
            deathAge: self.deathAge,
            sex: self.sex
        )
        if let encoded = try? encoder.encode(snapshot) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadFromUserDefaults() {
        let decoder = JSONDecoder()
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let snapshot = try? decoder.decode(UserDataSnapshot.self, from: savedData) {
            self.name = snapshot.name
            self.birthday = snapshot.birthday
            self.deathDate = snapshot.deathDate
            self.age = snapshot.age
            self.deathAge = snapshot.deathAge
            self.sex = snapshot.sex
        }
    }
}


struct UserDataSnapshot: Codable {
    var name: String
    var birthday: Date
    var deathDate: Date
    var age: Int
    var deathAge: Int
    var sex: String
}
