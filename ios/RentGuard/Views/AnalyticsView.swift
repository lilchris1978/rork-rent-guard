//
//  AnalyticsView.swift
//  RentGuard
//
//  Analytics dashboard with category breakdown and response metrics
//

import SwiftUI

struct AnalyticsView: View {
    let viewModel: TicketViewModel

    private let maxBarHeight: CGFloat = 140

    var body: some View {
        ZStack {
            BackgroundView().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    responseMetrics
                    categoryBreakdown
                    resolutionStats
                }
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 120)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Analytics")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Response times & ticket trends")
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.68))
        }
    }

    private var responseMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response Performance")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text(String(format: "%.0fm", viewModel.averageResponseMinutes))
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.82, blue: 0.78))
                    Text("Avg resolution")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 6) {
                    Text("\(viewModel.urgentCount)")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.26))
                    Text("Urgent open")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
            }

            HStack(spacing: 12) {
                VStack(spacing: 6) {
                    Text("\(viewModel.openCount)")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Total open")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 6) {
                    Text("+\(viewModel.resolvedTodayCount)")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.31, green: 0.82, blue: 0.37))
                    Text("Resolved today")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tickets by Category")
                .font(.headline)
                .foregroundStyle(.white)

            let maxCount = viewModel.categoryBreakdown.map(\.1).max() ?? 1

            ForEach(viewModel.categoryBreakdown, id: \.0) { category, count in
                HStack(spacing: 14) {
                    Image(systemName: category.iconName)
                        .foregroundStyle(category.tint)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(category.tint)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.08))
                                    .frame(height: 6)

                                Capsule()
                                    .fill(category.tint)
                                    .frame(
                                        width: maxCount > 0
                                            ? geometry.size.width * CGFloat(count) / CGFloat(maxCount)
                                            : 0,
                                        height: 6
                                    )
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: count)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var resolutionStats: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Performance")
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                statRow(
                    iconName: "brain.head.profile",
                    iconColor: Color(red: 0.80, green: 0.35, blue: 0.85),
                    title: "AI Classification Accuracy",
                    value: "96%",
                    subtitle: "Past 30 days"
                )
                Divider().overlay(.white.opacity(0.1))
                statRow(
                    iconName: "timer",
                    iconColor: Color(red: 0.18, green: 0.82, blue: 0.78),
                    title: "Auto-reply Rate",
                    value: "82%",
                    subtitle: "Messages handled by AI"
                )
                Divider().overlay(.white.opacity(0.1))
                statRow(
                    iconName: "arrow.triangle.2.circlepath",
                    iconColor: Color(red: 0.96, green: 0.73, blue: 0.29),
                    title: "Follow-up Completion",
                    value: "91%",
                    subtitle: "Tenants confirmed resolution"
                )
            }
        }
        .padding(18)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func statRow(
        iconName: String, iconColor: Color,
        title: String, value: String, subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.black)
                .fontDesign(.rounded)
                .foregroundStyle(iconColor)
        }
    }
}
