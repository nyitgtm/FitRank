import SwiftUI
import FirebaseAuth

// MARK: - Notifications Sheet

struct NotificationsSheet: View {
    let notifications: [CommunityNotification]
    var onTapNotification: (CommunityNotification) -> Void
    var onMarkAllRead: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No notifications yet")
                            .font(.headline)
                        Text("You'll see likes and comments here")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(notifications) { notification in
                                NotificationRow(
                                    notification: notification,
                                    onTap: { onTapNotification(notification) }
                                )
                                Divider()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !notifications.isEmpty {
                        Button("Mark All Read") {
                            onMarkAllRead()
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: CommunityNotification
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: notification.type == "like" ? "heart.fill" : "message.fill")
                    .font(.system(size: 20))
                    .foregroundColor(notification.type == "like" ? .red : .blue)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    // Message
                    Text(notification.type == "like" 
                         ? "\(notification.actorName) liked your post"
                         : "\(notification.actorName) commented on your post")
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.primary)
                    
                    // Post preview
                    Text(notification.postText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    // Time
                    Text(notification.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        }
        .buttonStyle(.plain)
    }
}
