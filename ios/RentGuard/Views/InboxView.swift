//
//  InboxView.swift
//  RentGuard
//
//  Main inbox with AI-triaged ticket list, haptics, and animated empty states
//

import SwiftUI

struct InboxView: View {
    let viewModel: TicketViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                metricsRow
                triageStrip
                if viewModel.filteredTickets.isEmpty {
                    emptyState
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    ticketList
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 120)
        }
        .background(BackgroundView().ignoresSafeArea())
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: viewModel.filteredTickets.count)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("RentGuard")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("AI inbox for tenant texts")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
            Spacer()
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 12) {
            MetricCard(
                value: "\(viewModel.openCount)", label: "Open",
                iconName: "tray.full.fill", tint: .white
            )
            MetricCard(
                value: "\(viewModel.urgentCount)", label: "Urgent",
                iconName: "exclamationmark.triangle.fill",
                tint: Color(red: 1.0, green: 0.42, blue: 0.26)
            )
            MetricCard(
                value: viewModel.resolvedTodayCount > 0 ? "+\(viewModel.resolvedTodayCount)" : "0",
                label: "Resolved today",
                iconName: "checkmark.circle.fill",
                tint: Color(red: 0.31, green: 0.82, blue: 0.37)
            )
        }
    }

    private var triageStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI categories")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedFilter == nil,
                    tint: .white
                ) {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        viewModel.selectedFilter = nil
                    }
                }
                ForEach(TicketCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: viewModel.selectedFilter == category,
                        tint: category.tint
                    ) {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            viewModel.selectedFilter =
                                viewModel.selectedFilter == category ? nil : category
                        }
                    }
                }
            }
        }
    }

    private var ticketList: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.filteredTickets.enumerated()), id: \.element.id) { index, ticket in
                NavigationLink(value: ticket) {
                    TicketRow(
                        ticket: ticket,
                        isSelected: viewModel.selectedTicketID == ticket.id
                    )
                }
                .buttonStyle(.plain)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            ZStack {
                Image(systemName: "tray.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.15))
                    .modifier(FloatingAnimation(delay: 0))
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37).opacity(0.4))
                    .offset(x: 22, y: -10)
                    .modifier(FloatingAnimation(delay: 0.6))
            }
            .frame(height: 80)

            VStack(spacing: 10) {
                Text(viewModel.selectedFilter != nil
                    ? "No \(viewModel.selectedFilter!.rawValue) tickets"
                    : "No tickets match this filter")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Text("Everything is under control")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer().frame(height: 60)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MetricCard: View {
    let value: String
    let label: String
    let iconName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: iconName).foregroundStyle(tint)
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.74))
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(isSelected ? tint : .white.opacity(0.08), in: Capsule())
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct TicketRow: View {
    let ticket: TenantTicketModel
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 13) {
            categoryIcon
            messageContent
            Spacer()
            trailingInfo
        }
        .padding(14)
        .background(
            isSelected ? AnyShapeStyle(.white.opacity(0.15)) : AnyShapeStyle(.white.opacity(0.07)),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    isSelected
                        ? ticket.category.tint.opacity(0.7)
                        : .white.opacity(0.08)
                )
        }
    }

    private var categoryIcon: some View {
        ZStack {
            Circle()
                .fill(ticket.category.tint.opacity(0.18))
                .frame(width: 42, height: 42)

            if ticket.priority <= 1 {
                Circle()
                    .stroke(ticket.category.tint, lineWidth: 2)
                    .frame(width: 42, height: 42)
                    .modifier(PulseAnimation())
            }

            Image(systemName: ticket.category.iconName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ticket.category.tint)
        }
    }

    private var messageContent: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(ticket.tenantName)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(ticket.unit)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.48))
                if ticket.priority <= 1 {
                    Text("PRIORITY")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(ticket.category.tint, in: Capsule())
                }
            }
            Text(ticket.message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .lineLimit(2)
            if ticket.hasVendorAssigned {
                HStack(spacing: 6) {
                    Image(systemName: ticket.assignedVendorTrade.iconName)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    Text("\(ticket.assignedVendorName)")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                        .lineLimit(1)
                    if !ticket.aiReply.isEmpty {
                        Text("·")
                            .foregroundStyle(.white.opacity(0.3))
                        Image(systemName: "bubble.right.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("Reply sent")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private var trailingInfo: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(ticket.relativeTime)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 6) {
                if ticket.hasPhoto {
                    Image(systemName: "photo.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                statusBadge
            }
        }
    }

    private var statusBadge: some View {
        Text(ticket.status.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(ticket.status.tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(ticket.status.tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Pulse Animation for Priority Tickets

struct PulseAnimation: ViewModifier {
    @State private var opacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.9
                }
            }
    }
}
