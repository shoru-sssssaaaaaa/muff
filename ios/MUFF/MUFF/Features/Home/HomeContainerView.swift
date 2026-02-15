import SwiftUI

enum HomeTab: CaseIterable {
    case popular
    case new
    case follow

    var label: String {
        switch self {
        case .popular: "人気"
        case .new: "新着"
        case .follow: "フォロー"
        }
    }

    var icon: String {
        switch self {
        case .popular: "🔥"
        case .new: "🆕"
        case .follow: "⭐"
        }
    }
}

struct HomeContainerView: View {
    @State private var selectedTab: HomeTab = .popular
    @State private var refreshTrigger = 0

    var body: some View {
        VStack(spacing: 0) {
            // Top tabs
            HStack(spacing: 0) {
                ForEach(HomeTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text(tab.icon)
                                    .font(.caption2)
                                Text(tab.label)
                                    .font(.subheadline)
                                    .fontWeight(selectedTab == tab ? .bold : .regular)
                            }
                            .foregroundStyle(selectedTab == tab ? .primary : .secondary)

                            Rectangle()
                                .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
            .background(Color(.systemGray6))

            Divider()

            // Content
            TabView(selection: $selectedTab) {
                PopularFeedView(refreshTrigger: refreshTrigger)
                    .tag(HomeTab.popular)

                NewFeedView(refreshTrigger: refreshTrigger)
                    .tag(HomeTab.new)

                FollowFeedView(refreshTrigger: refreshTrigger)
                    .tag(HomeTab.follow)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(.systemGray5))
        .navigationTitle("MUFF")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    refreshTrigger += 1
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
}
