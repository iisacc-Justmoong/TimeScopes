//
//  UserInfoHeaderView.swift
//  Chrono
//
//  Created by 윤무영 on 11/8/24.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        VStack (alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width:48 , height:  48)
                VStack (alignment: .leading){
                    Text(userData.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(DateUtility.dateFormatter.string(from: userData.birthday))")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Gauge(value: max(0, Double(userData.age)), in: 0...max(1, Double(userData.deathAge))) {
//                    Text(String(format: "%.0f", Double(userData.age)))
                    Text("\(userData.deathAge > 0 ? (Double(userData.age) / Double(userData.deathAge) * 100) : 0, specifier: "%.0f")%")
                        .font(.headline)
                }
                        .gaugeStyle(.accessoryCircularCapacity)
                        .foregroundStyle(Color.accentColor)
                        .tint(Color.accentColor)
            }
            HStack{
                Text("\(userData.age)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
                Gauge(value: max(0, Float(userData.age)), in: 0...max(1, Float(userData.deathAge))) {
                    
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(Color.accentColor)
                Text("\(userData.deathAge)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

#Preview {
    UserProfileView()
        .environmentObject(UserData())
}
