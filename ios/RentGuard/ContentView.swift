//
//  ContentView.swift
//  RentGuard
//
//  Tab navigation shell — gated by auth, then by profile setup
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AuthManager.self) private var auth
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = TicketViewModel()
    @Query private var profiles: [LandlordProfileModel]
    @State private var navigateToTicketID: UUID?

    var body: some View {
        Group {
            if auth.isLoading {
                launchScreen
            } else if auth.user == nil {
                AuthView()
            } else if profiles.isEmpty {
                LoginView()
            } else {
                mainContent
            }
        }
    }

    private var launchScreen: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.18, green: 0.82, blue: 0.78),
                                Color(red: 0.09, green: 0.62, blue: 0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                ProgressView()
                    .tint(.white)
            }
        }
    }

    private var mainContent: some View {
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
                TenantsView()
            }
            .tabItem {
                Label("Tenants", systemImage: "person.2.fill")
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
                Label("Vendors", systemImage: "wrench.and.screwdriver.fill")
            }

            NavigationStack {
                SettingsView(authManager: auth)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Color(red: 0.18, green: 0.82, blue: 0.78))
        .onAppear {
            viewModel.configure(with: modelContext)
            viewModel.notificationService = notificationService
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .openTicketNotification)
        ) { notification in
            if let ticketIDString = notification.userInfo?["ticketID"] as? String,
               let ticketID = UUID(uuidString: ticketIDString) {
                viewModel.selectedTicketID = ticketID
            }
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
        .environment(AuthManager())
        .environment(NotificationService())
        .modelContainer(for: [TenantTicketModel.self, TenantModel.self])
}
