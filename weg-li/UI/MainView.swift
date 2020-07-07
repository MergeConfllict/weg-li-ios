//
//  MainView.swift
//  weg-li
//
//  Created by Stefan Trauth on 08.10.19.
//  Copyright © 2019 Stefan Trauth. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @State private var showReportForm: Bool = false
    @State private var showPersonalData: Bool = false
    
    @State private var wasReportEdited = false
    @State private var presentDraftAlert = false
    
    @State private var showingSheet = false
    
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        NavigationView {
            VStack {
                Button(action: {
                    self.showReportForm.toggle()
                }) {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .iconModifier()
                        Text("Neue Anzeige")
                    }
                    .font(.headline)
                }.buttonStyle(EditButtonStyle())
            }
            .navigationBarTitle("weg-li")
            .navigationBarItems(trailing: contactDataIcon)
            .sheet(isPresented: $showReportForm) {
                ReportForm()
                    .environmentObject(self.store)
            }
        }
        .sheet(isPresented: $showPersonalData) {
            PersonalData(isPresented: self.$showPersonalData, viewModel: PersonalDataViewModel(model: self.store.state.contact))
                .environmentObject(self.store)
        }
    }
    
    private var contactDataIcon: some View {
        Button(action: {
            self.showPersonalData.toggle()
        }, label: {
            Image(systemName: "person.circle.fill")
                .iconModifier()
        })
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}