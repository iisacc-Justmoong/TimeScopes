//
//  InputView.swift
//  Chrono
//
//  Created by ymy on 1/27/25.
//

import SwiftUI

struct InputView: View {
    
    @EnvironmentObject var userData: UserData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $userData.name)
                    
                    DatePicker("Start date", selection: $userData.birthday, displayedComponents: .date)
                    DatePicker("End Date", selection: $userData.deathDate, displayedComponents: .date)
                }
                footer: {
                    Text("When you enter the start and end dates, it displays information about the time you've spent so far based on the current point and reference information that can help you with future activities.")
                        
                }
            }
            .navigationTitle("Insert Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        userData.saveProfile()
                        dismiss()
                    }
                }
            }
            
        }
    }
}
    
#Preview {
    InputView()
        .environmentObject(UserData())
}
