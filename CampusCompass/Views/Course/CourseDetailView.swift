import SwiftUI
import SwiftData
import FirebaseFirestore
import FirebaseAuth

extension CourseDetailView {
    public init(course: Course) {
        self.course = course
    }
}

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
    @State private var firebaseComments: [CourseComment] = []
    
    @Query private var users: [User]
    
    private var currentUser: User? {
        if let currentUserId = Auth.auth().currentUser?.uid {
            return users.first { $0.userId == currentUserId }
        }
        return nil
    }
    
    private var commentsListener: ListenerRegistration?
    
    private var submitButtonBackground: Color {
        if newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting {
            return Color.gray
        } else {
            return Color.blue
        }
    }
    
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
        .onAppear {
            setupCommentsListener()
            print("Courses ClassTime Count: \(course.classTimes.count)")
            for (index, classTime) in course.classTimes.enumerated() {
                print("Time Period \(index): Week\(classTime.dayOfWeek), \(formatTime(classTime.startTime)) - \(formatTime(classTime.endTime)), Location: \(classTime.location)")
            }
            
            if let currentUser = currentUser {
                    print("Current user: \(currentUser.username), ID: \(currentUser.userId)")
                } else {
                    print("No current user found")
                }
                
                if let firebaseUser = Auth.auth().currentUser {
                    print("Firebase Auth current user ID: \(firebaseUser.uid)")
                } else {
                    print("No Firebase Auth current user")
                }
        }
        .onDisappear {
            commentsListener?.remove()
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
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
                
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(String(format: "%.1f", calculateAverageRating()))
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
                    ForEach(Array(course.classTimes.enumerated()), id: \.offset) { index, classTime in
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
    
    private var addReviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Your Review")
                .font(.headline)
                .foregroundColor(.primary)
            
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
                    .onSubmit {  
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
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
    
    private var reviewsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Course Reviews")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(firebaseComments.count) reviews")
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
            
            if firebaseComments.isEmpty {
                emptyReviewsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(firebaseComments.sorted { $0.commentDate > $1.commentDate }) { comment in
                        ReviewCard(
                            comment: comment,
                            currentUserId: currentUser?.userId,
                            onDelete: {
                                deleteComment(comment)
                            }
                        )
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
        
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
        
    private func setupCommentsListener() {
        let db = Firestore.firestore()
        
        db.collection("courseComments")
            .whereField("courseId", isEqualTo: course.courseId)
            .order(by: "commentDate", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error listening to comments: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                var comments: [CourseComment] = []
                let group = DispatchGroup()
                
                for document in documents {
                    let data = document.data()
                    let commentId = data["commentId"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let rating = data["rating"] as? Int ?? 5
                    let authorId = data["authorId"] as? String ?? ""
                    let authorUsername = data["authorUsername"] as? String ?? ""
                    
                    let comment = CourseComment(
                        commentId: commentId,
                        content: content,
                        rating: rating
                    )
                    
                    if let timestamp = data["commentDate"] as? Timestamp {
                        comment.commentDate = timestamp.dateValue()
                    }
                    
                    group.enter()
                    self.fetchAuthorInfo(authorId: authorId, authorUsername: authorUsername) { author in
                        comment.author = author
                        group.leave()
                    }
                    
                    comments.append(comment)
                }
                
                group.notify(queue: .main) {
                    self.firebaseComments = comments
                }
            }
    }
    
    private func fetchAuthorInfo(authorId: String, authorUsername: String, completion: @escaping (User) -> Void) {
        if let localUser = users.first(where: { $0.userId == authorId }) {
            completion(localUser)
            return
        }
        
        FirebaseService.shared.getUserData(userId: authorId) { result in
            switch result {
            case .success(let user):
                completion(user)
            case .failure:
                let fallbackUser = User(
                    userId: authorId,
                    username: authorUsername,
                    password: "",
                    email: "",
                    gender: "Unknown"
                )
                completion(fallbackUser)
            }
        }
    }
    
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
        
        FirebaseService.shared.addCourseComment(
            courseId: course.courseId,
            content: trimmedText,
            rating: newCommentRating,
            author: currentUser
        ) { result in
            DispatchQueue.main.async {
                self.isSubmitting = false
                
                switch result {
                case .success:
                    self.newCommentText = ""
                    self.newCommentRating = 5
                    self.showAlert(message: "Review submitted successfully!")
                    
                case .failure(let error):
                    self.showAlert(message: "Failed to submit review: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func refreshComments() {
        isRefreshing = true
        
        FirebaseService.shared.fetchCourseComments(courseId: course.courseId) { result in
            DispatchQueue.main.async {
                self.isRefreshing = false
                
                switch result {
                case .success(let comments):
                    self.firebaseComments = comments
                    
                case .failure(let error):
                    self.showAlert(message: "Failed to refresh comments: \(error.localizedDescription)")
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
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            showAlert(message: "Please login to delete review")
            return
        }
        
        guard let authorId = comment.author?.userId,
              currentUserId == authorId else {
            showAlert(message: "You can only delete your own reviews")
            return
        }
        
        FirebaseService.shared.deleteCourseComment(commentId: comment.commentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.firebaseComments.removeAll { $0.commentId == comment.commentId }
                    self.showAlert(message: "Review deleted successfully!")
                    
                case .failure(let error):
                    self.showAlert(message: "Failed to delete review: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculateAverageRating() -> Double {
        guard !firebaseComments.isEmpty else { return 0.0 }
        let total = firebaseComments.reduce(0) { $0 + Double($1.rating) }
        return total / Double(firebaseComments.count)
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
}

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

struct ReviewCard: View {
    let comment: CourseComment
    let currentUserId: String?
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.author?.username ?? "Unknown User")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
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
        guard let currentUserId = Auth.auth().currentUser?.uid,
              let authorId = comment.author?.userId else {
            return false
        }
        return currentUserId == authorId
    }
}
