//
//  ContentView.swift
//  RentGuard
//
//  Tab navigation shell — Inbox, Analytics, Settings
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TicketViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                InboxView(viewModel: viewModel)
                    .navigationDestination(for: TenantTicketModel.self) { ticket in
                        TicketDetailView(ticket: ticket, viewModel: viewModel)
                    }
            }
            .tabItem {
                Label("Inbox", systemImage: "tray.full.fill")
            }

            NavigationStack {
                AnalyticsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                VendorManagementView(viewModel: viewModel)
            }
            .tabItem {
                Label("Vendors", systemImage: "person.3.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
        .onAppear {
            viewModel.configure(with: modelContext)
        }
    }
}

struct BackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.06, blue: 0.10),
                Color(red: 0.04, green: 0.12, blue: 0.18),
                Color(red: 0.01, green: 0.03, blue: 0.05)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(red: 0.16, green: 0.92, blue: 0.84).opacity(0.24))
                .frame(width: 220, height: 220)
                .blur(radius: 60)
                .offset(x: 70, y: -60)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color(red: 1.0, green: 0.51, blue: 0.27).opacity(0.18))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -90, y: 80)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [TenantTicketModel.self])
}
