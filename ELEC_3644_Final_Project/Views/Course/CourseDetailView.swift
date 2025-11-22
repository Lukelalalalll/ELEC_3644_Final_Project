
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
        users.first // 假设第一个用户是当前登录用户
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 课程基本信息
                VStack(alignment: .leading, spacing: 12) {
                    Text(course.courseName)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(course.courseCode)
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Professor: \(course.professor)")
                    }
                    .font(.headline)
                    
                    HStack {
                        Image(systemName: "number.circle.fill")
                        Text("Credits: \(course.credits)")
                    }
                    .font(.subheadline)
                    
                    // 平均评分
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", course.averageRating()))
                        Text("(\(course.comments.count) reviews)")
                    }
                    .font(.subheadline)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 课程描述
                VStack(alignment: .leading, spacing: 10) {
                    Text("Course Description")
                        .font(.headline)
                    
                    Text(course.courseDescription)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 上课时间
                VStack(alignment: .leading, spacing: 10) {
                    Text("Class Schedule")
                        .font(.headline)
                    
                    ForEach(course.classTimes, id: \.dayOfWeek) { classTime in
                        HStack {
                            Image(systemName: "clock.fill")
                            Text(classTime.timeString())
                            Spacer()
                            Text(classTime.location)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 添加评论区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Your Review")
                        .font(.headline)
                    
                    // 评分选择
                    HStack {
                        Text("Rating:")
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= newCommentRating ? "star.fill" : "star")
                                .foregroundColor(star <= newCommentRating ? .yellow : .gray)
                                .onTapGesture {
                                    newCommentRating = star
                                }
                        }
                    }
                    
                    TextField("Write your review here...", text: $newCommentText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    Button("Submit Review") {
                        submitReview()
                    }
                    .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 现有评论
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Course Reviews")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(course.comments.count) reviews")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if course.comments.isEmpty {
                        Text("No reviews yet. Be the first to review!")
                            .foregroundColor(.secondary)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
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
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // 底部间距，确保内容不会被 TabBar 遮挡
                Spacer()
                    .frame(height: 100) // 为底部 TabBar 预留空间
            }
            .padding(.horizontal)
            .padding(.top, 1) // 减少顶部间距，让内容更靠上
        }
        .navigationTitle("Course Details")
        .navigationBarTitleDisplayMode(.inline)
        // 隐藏默认的 TabBar
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
        
        // 清空输入
        newCommentText = ""
        newCommentRating = 5
        
        // 保存更改
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

// 评论卡片组件
struct ReviewCard: View {
    let comment: CourseComment
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 评分和日期
            HStack {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= comment.rating ? "star.fill" : "star")
                            .foregroundColor(star <= comment.rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Text(formatDate(comment.commentDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 删除按钮
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            // 评论内容
            Text(comment.content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
