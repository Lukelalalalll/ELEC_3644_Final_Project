import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: Course
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCommentText = ""
    @State private var newCommentRating = 5
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(course.courseCode)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(course.courseName)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(course.professor)
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "number.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("\(course.credits) credits")
                                .font(.subheadline)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", course.averageRating()))
                                .font(.subheadline)
                            Text("(\(course.comments.count))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Course Description")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(course.courseDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Class Schedule")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        ForEach(course.classTimes, id: \.dayOfWeek) { classTime in
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.orange)
                                        .frame(width: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(classTime.timeString())
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text(classTime.location)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(classTime.dayName())
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(20)
                            }
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(30)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Your Review")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Review")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Share your thoughts about this course...", text: $newCommentText, axis: .vertical)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(30)
                            .lineLimit(3...6)
                    }
                    
                    Button(action: submitReview) {
                        HStack {
                            Spacer()
                            Text("Submit Review")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(30)
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // 现有评论
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Course Reviews")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(course.comments.count) reviews")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if course.comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No reviews yet")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Be the first to share your experience!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(course.comments.sorted { $0.commentDate > $1.commentDate }) { comment in
                                ReviewCard(comment: comment, onDelete: {
                                    deleteComment(comment)
                                })
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(30)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                Spacer()
                    .frame(height: 60)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func submitReview() {
        guard let currentUser = currentUser else { return }
        
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newComment = CourseComment(
            commentId: UUID().uuidString,
            content: trimmedText,
            rating: newCommentRating,
            author: currentUser,
            course: course
        )
        
        modelContext.insert(newComment)

        newCommentText = ""
        newCommentRating = 5
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save comment: \(error)")
        }
    }
    
    private func deleteComment(_ comment: CourseComment) {
        modelContext.delete(comment)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete comment: \(error)")
        }
    }
}

struct ReviewCard: View {
    let comment: CourseComment
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息栏
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.author?.username ?? "Unknown User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(formatDate(comment.commentDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

extension ClassTime {
    func dayName() -> String {
        let dayNames = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return dayNames.indices.contains(dayOfWeek) ? dayNames[dayOfWeek] : "Unknown"
    }
}
