//import SwiftUI
//import SwiftData
//
//struct CourseDetailView: View {
//    let course: Course
//    @Environment(\.modelContext) private var modelContext
//    @Environment(\.dismiss) private var dismiss
//    
//    @State private var newCommentText = ""
//    @State private var newCommentRating = 5
//    @State private var isSubmitting = false
//    @State private var isRefreshing = false
//    @State private var showAlert = false
//    @State private var alertMessage = ""
//    
//    @Query private var users: [User]
//    
//    private var currentUser: User? {
//        users.first
//    }
//    
//    // 计算属性：按钮背景色
//    private var submitButtonBackground: Color {
//        if newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting {
//            return Color.gray
//        } else {
//            return Color.blue
//        }
//    }
//    
//    // 计算属性：按钮是否禁用
//    private var isSubmitDisabled: Bool {
//        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 24) {
//                courseInfoCard
//                courseDescriptionCard
//                classScheduleCard
//                addReviewCard
//                reviewsCard
//                
//                Spacer()
//                    .frame(height: 60)
//            }
//            .padding(.horizontal)
//            .padding(.top, 8)
//        }
//        .background(Color(.systemGroupedBackground))
//        .navigationTitle("Course Details")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar(.hidden, for: .tabBar)
//        .alert("Message", isPresented: $showAlert) {
//            Button("OK", role: .cancel) { }
//        } message: {
//            Text(alertMessage)
//        }
//        .refreshable {
//            await refreshCommentsAsync()
//        }
//    }
//    
//    // MARK: - 子视图组件
//    
//    // 课程信息卡片
//    private var courseInfoCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text(course.courseCode)
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(.primary)
//            
//            Text(course.courseName)
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            HStack(spacing: 20) {
//                HStack(spacing: 6) {
//                    Image(systemName: "person.fill")
//                        .foregroundColor(.blue)
//                        .font(.caption)
//                    Text(course.professor)
//                        .font(.subheadline)
//                }
//                
//                HStack(spacing: 6) {
//                    Image(systemName: "number.circle.fill")
//                        .foregroundColor(.green)
//                        .font(.caption)
//                    Text("\(course.credits) credits")
//                        .font(.subheadline)
//                }
//                
//                // 平均评分
//                HStack(spacing: 6) {
//                    Image(systemName: "star.fill")
//                        .foregroundColor(.orange)
//                        .font(.caption)
//                    Text(String(format: "%.1f", course.averageRating()))
//                        .font(.subheadline)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//    }
//    
//    // 课程描述卡片
//    private var courseDescriptionCard: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Course Description")
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            Text(course.courseDescription)
//                .font(.body)
//                .foregroundColor(.secondary)
//                .lineSpacing(4)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//    }
//    
//    // 上课时间卡片
//    private var classScheduleCard: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Class Schedule")
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            VStack(spacing: 12) {
//                ForEach(course.classTimes, id: \.dayOfWeek) { classTime in
//                    ClassTimeRow(classTime: classTime)
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//    }
//    
//    // 添加评论卡片
//    private var addReviewCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Add Your Review")
//                .font(.headline)
//                .foregroundColor(.primary)
//            
//            // 评分选择
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Rating")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                HStack {
//                    ForEach(1...5, id: \.self) { star in
//                        Image(systemName: star <= newCommentRating ? "star.fill" : "star")
//                            .foregroundColor(.orange)
//                            .font(.title2)
//                            .onTapGesture {
//                                newCommentRating = star
//                            }
//                    }
//                }
//            }
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Your Review")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                TextField("Share your thoughts about this course...", text: $newCommentText, axis: .vertical)
//                    .padding(12)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(30)
//                    .lineLimit(3...6)
//            }
//            
//            Button(action: submitReview) {
//                HStack {
//                    if isSubmitting {
//                        ProgressView()
//                            .scaleEffect(0.8)
//                            .tint(.white)
//                    }
//                    
//                    Text(isSubmitting ? "Submitting..." : "Submit Review")
//                        .font(.headline)
//                        .foregroundColor(.white)
//                }
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 12)
//                .background(submitButtonBackground)
//                .cornerRadius(30)
//            }
//            .disabled(isSubmitDisabled)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//    }
//    
//    // 评论列表卡片
//    private var reviewsCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Text("Course Reviews")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                HStack(spacing: 8) {
//                    Text("\(course.comments.count) reviews")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    Button(action: refreshComments) {
//                        Image(systemName: "arrow.clockwise")
//                            .font(.subheadline)
//                            .foregroundColor(.blue)
//                    }
//                    .disabled(isRefreshing)
//                }
//            }
//            
//            if course.comments.isEmpty {
//                emptyReviewsView
//            } else {
//                LazyVStack(spacing: 16) {
//                    ForEach(course.comments.sorted { $0.commentDate > $1.commentDate }) { comment in
//                        ReviewCard(comment: comment, onDelete: {
//                            deleteComment(comment)
//                        })
//                    }
//                }
//            }
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(20)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
//    }
//    
//    // 空评论视图
//    private var emptyReviewsView: some View {
//        VStack(spacing: 12) {
//            Image(systemName: "bubble.left")
//                .font(.system(size: 40))
//                .foregroundColor(.gray.opacity(0.5))
//            Text("No reviews yet")
//                .font(.headline)
//                .foregroundColor(.primary)
//            Text("Be the first to share your experience!")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(40)
//    }
//    
//    // MARK: - 方法
//    
//    private func submitReview() {
//        guard let currentUser = currentUser else {
//            showAlert(message: "Please login to submit a review")
//            return
//        }
//        
//        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
//        guard !trimmedText.isEmpty else {
//            showAlert(message: "Please enter your review content")
//            return
//        }
//        
//        isSubmitting = true
//        
//        // 同步到 Firebase
//        FirebaseService.shared.addCourseComment(
//            courseId: course.courseId,
//            content: trimmedText,
//            rating: newCommentRating,
//            author: currentUser
//        ) { result in
//            DispatchQueue.main.async {
//                isSubmitting = false
//                
//                switch result {
//                case .success(let firebaseComment):
//                    // 创建本地评论对象
//                    let localComment = CourseComment(
//                        commentId: firebaseComment.commentId,
//                        content: trimmedText,
//                        rating: newCommentRating,
//                        author: currentUser,
//                        course: course
//                    )
//                    localComment.commentDate = firebaseComment.commentDate
//                    
//                    // 保存到本地
//                    modelContext.insert(localComment)
//                    
//                    do {
//                        try modelContext.save()
//                        newCommentText = ""
//                        newCommentRating = 5
//                        showAlert(message: "Review submitted successfully!")
//                    } catch {
//                        showAlert(message: "Failed to save review locally: \(error.localizedDescription)")
//                    }
//                    
//                case .failure(let error):
//                    showAlert(message: "Failed to submit review: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func refreshComments() {
//        isRefreshing = true
//        
//        FirebaseService.shared.fetchCourseComments(courseId: course.courseId) { result in
//            DispatchQueue.main.async {
//                isRefreshing = false
//                
//                switch result {
//                case .success(let firebaseComments):
//                    // 清除本地评论
//                    for comment in course.comments {
//                        modelContext.delete(comment)
//                    }
//                    
//                    // 添加从 Firebase 获取的评论
//                    for firebaseComment in firebaseComments {
//                        let localComment = CourseComment(
//                            commentId: firebaseComment.commentId,
//                            content: firebaseComment.content,
//                            rating: firebaseComment.rating,
//                            author: firebaseComment.author,
//                            course: course
//                        )
//                        localComment.commentDate = firebaseComment.commentDate
//                        modelContext.insert(localComment)
//                    }
//                    
//                    do {
//                        try modelContext.save()
//                        showAlert(message: "Comments refreshed successfully!")
//                    } catch {
//                        showAlert(message: "Failed to refresh comments: \(error.localizedDescription)")
//                    }
//                    
//                case .failure(let error):
//                    showAlert(message: "Failed to refresh comments: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func refreshCommentsAsync() async {
//        await withCheckedContinuation { continuation in
//            refreshComments()
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                continuation.resume()
//            }
//        }
//    }
//    
//    private func deleteComment(_ comment: CourseComment) {
//        // 从 Firebase 删除
//        FirebaseService.shared.deleteCourseComment(commentId: comment.commentId) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success:
//                    // 从本地删除
//                    modelContext.delete(comment)
//                    do {
//                        try modelContext.save()
//                        showAlert(message: "Review deleted successfully!")
//                    } catch {
//                        showAlert(message: "Failed to delete review locally: \(error.localizedDescription)")
//                    }
//                    
//                case .failure(let error):
//                    showAlert(message: "Failed to delete review: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func showAlert(message: String) {
//        alertMessage = message
//        showAlert = true
//    }
//}
//
//// MARK: - 子视图
//
//// 上课时间行
//struct ClassTimeRow: View {
//    let classTime: ClassTime
//    
//    var body: some View {
//        HStack {
//            HStack(spacing: 12) {
//                Image(systemName: "clock.fill")
//                    .foregroundColor(.orange)
//                    .frame(width: 20)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    Text(classTime.timeString())
//                        .font(.subheadline)
//                        .foregroundColor(.primary)
//                    Text(classTime.location)
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//            }
//            
//            Spacer()
//            
//            // 修复：使用 ClassTime 中实际存在的方法
//            Text(classTime.dayOfWeekString()) 
//                .font(.caption)
//                .fontWeight(.medium)
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(Color.blue.opacity(0.1))
//                .foregroundColor(.blue)
//                .cornerRadius(20)
//        }
//        .padding(12)
//        .background(Color(.systemGray6))
//        .cornerRadius(30)
//    }
//}
//
//// 评论卡片
//struct ReviewCard: View {
//    let comment: CourseComment
//    let onDelete: () -> Void
//    
//    @State private var showDeleteAlert = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            // 顶部信息栏
//            HStack(alignment: .top) {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(comment.author?.username ?? "Unknown User")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(.primary)
//                    
//                    // 显示评分
//                    HStack(spacing: 2) {
//                        ForEach(1...5, id: \.self) { star in
//                            Image(systemName: star <= comment.rating ? "star.fill" : "star")
//                                .foregroundColor(.orange)
//                                .font(.caption)
//                        }
//                    }
//                    
//                    Text(formatDate(comment.commentDate))
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//
//                // 只有评论作者可以删除
//                if isCurrentUserAuthor() {
//                    Button(action: {
//                        showDeleteAlert = true
//                    }) {
//                        Image(systemName: "trash")
//                            .font(.caption)
//                            .foregroundColor(.red.opacity(0.7))
//                            .padding(6)
//                            .background(Color.red.opacity(0.1))
//                            .clipShape(Circle())
//                    }
//                }
//            }
//
//            Text(comment.content)
//                .font(.body)
//                .foregroundColor(.primary)
//                .lineSpacing(2)
//        }
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(16)
//        .background(Color(.systemBackground))
//        .cornerRadius(30)
//        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
//        )
//        .alert("Delete Review", isPresented: $showDeleteAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//                onDelete()
//            }
//        } message: {
//            Text("Are you sure you want to delete this review? This action cannot be undone.")
//        }
//    }
//    
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//    
//    private func isCurrentUserAuthor() -> Bool {
//        // 这里需要获取当前用户并比较
//        // 简化版本：假设可以删除（实际应用中应该检查权限）
//        return true
//    }
//}





import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: Course
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCommentText = ""
    @State private var newCommentRating = 5
    @State private var isSubmitting = false
    @State private var isRefreshing = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @Query private var users: [User]
    
    private var currentUser: User? {
        users.first
    }
    
    // 计算属性：按钮背景色
    private var submitButtonBackground: Color {
        if newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting {
            return Color.gray
        } else {
            return Color.blue
        }
    }
    
    // 计算属性：按钮是否禁用
    private var isSubmitDisabled: Bool {
        newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                courseInfoCard
                courseDescriptionCard
                classScheduleCard
                addReviewCard
                reviewsCard
                
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
        .alert("Message", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .refreshable {
            await refreshCommentsAsync()
        }
    }
    
    // MARK: - 子视图组件
    
    // 课程信息卡片
    private var courseInfoCard: some View {
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
                
                // 平均评分
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(String(format: "%.1f", course.averageRating()))
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 课程描述卡片
    private var courseDescriptionCard: some View {
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
    }
    
    // 上课时间卡片
    private var classScheduleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Class Schedule")
                .font(.headline)
                .foregroundColor(.primary)
            
            if course.classTimes.isEmpty {
                Text("No schedule available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            } else {
                VStack(spacing: 12) {
                    ForEach(course.classTimes, id: \.dayOfWeek) { classTime in
                        ClassTimeRow(classTime: classTime)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 添加评论卡片
    private var addReviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Your Review")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 评分选择
            VStack(alignment: .leading, spacing: 8) {
                Text("Rating")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= newCommentRating ? "star.fill" : "star")
                            .foregroundColor(.orange)
                            .font(.title2)
                            .onTapGesture {
                                newCommentRating = star
                            }
                    }
                }
            }
            
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
                    if isSubmitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    }
                    
                    Text(isSubmitting ? "Submitting..." : "Submit Review")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(submitButtonBackground)
                .cornerRadius(30)
            }
            .disabled(isSubmitDisabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // 评论列表卡片
    private var reviewsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Course Reviews")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(course.comments.count) reviews")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: refreshComments) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .disabled(isRefreshing)
                }
            }
            
            if course.comments.isEmpty {
                emptyReviewsView
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
    }
    
    // 空评论视图
    private var emptyReviewsView: some View {
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
    }
    
    // MARK: - 方法
    
    private func submitReview() {
        guard let currentUser = currentUser else {
            showAlert(message: "Please login to submit a review")
            return
        }
        
        let trimmedText = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            showAlert(message: "Please enter your review content")
            return
        }
        
        isSubmitting = true
        
        // 同步到 Firebase
        FirebaseService.shared.addCourseComment(
            courseId: course.courseId,
            content: trimmedText,
            rating: newCommentRating,
            author: currentUser
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                
                switch result {
                case .success(let firebaseComment):
                    // 创建本地评论对象
                    let localComment = CourseComment(
                        commentId: firebaseComment.commentId,
                        content: trimmedText,
                        rating: newCommentRating,
                        author: currentUser,
                        course: course
                    )
                    localComment.commentDate = firebaseComment.commentDate
                    
                    // 保存到本地
                    modelContext.insert(localComment)
                    
                    do {
                        try modelContext.save()
                        newCommentText = ""
                        newCommentRating = 5
                        showAlert(message: "Review submitted successfully!")
                    } catch {
                        showAlert(message: "Failed to save review locally: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    showAlert(message: "Failed to submit review: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshComments() {
        isRefreshing = true
        
        FirebaseService.shared.fetchCourseComments(courseId: course.courseId) { result in
            DispatchQueue.main.async {
                isRefreshing = false
                
                switch result {
                case .success(let firebaseComments):
                    // 清除本地评论
                    for comment in course.comments {
                        modelContext.delete(comment)
                    }
                    
                    // 添加从 Firebase 获取的评论
                    for firebaseComment in firebaseComments {
                        let localComment = CourseComment(
                            commentId: firebaseComment.commentId,
                            content: firebaseComment.content,
                            rating: firebaseComment.rating,
                            author: firebaseComment.author,
                            course: course
                        )
                        localComment.commentDate = firebaseComment.commentDate
                        modelContext.insert(localComment)
                    }
                    
                    do {
                        try modelContext.save()
                        showAlert(message: "Comments refreshed successfully!")
                    } catch {
                        showAlert(message: "Failed to refresh comments: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    showAlert(message: "Failed to refresh comments: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshCommentsAsync() async {
        await withCheckedContinuation { continuation in
            refreshComments()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                continuation.resume()
            }
        }
    }
    
    private func deleteComment(_ comment: CourseComment) {
        // 从 Firebase 删除
        FirebaseService.shared.deleteCourseComment(commentId: comment.commentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 从本地删除
                    modelContext.delete(comment)
                    do {
                        try modelContext.save()
                        showAlert(message: "Review deleted successfully!")
                    } catch {
                        showAlert(message: "Failed to delete review locally: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    showAlert(message: "Failed to delete review: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

// MARK: - 子视图

// 上课时间行
struct ClassTimeRow: View {
    let classTime: ClassTime
    
    private var dayOfWeekString: String {
        let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayNames.indices.contains(classTime.dayOfWeek) ? dayNames[classTime.dayOfWeek] : "Unknown"
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.string(from: classTime.startTime)
        let end = formatter.string(from: classTime.endTime)
        return "\(start) - \(end)"
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(classTime.location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(dayOfWeekString)
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

// 评论卡片
struct ReviewCard: View {
    let comment: CourseComment
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息栏
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.author?.username ?? "Unknown User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    // 显示评分
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= comment.rating ? "star.fill" : "star")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                    }
                    
                    Text(formatDate(comment.commentDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()

                // 只有评论作者可以删除
                if isCurrentUserAuthor() {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.7))
                            .padding(6)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
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
        .alert("Delete Review", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this review? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func isCurrentUserAuthor() -> Bool {
        // 这里需要获取当前用户并比较
        // 简化版本：假设可以删除（实际应用中应该检查权限）
        return true
    }
}
