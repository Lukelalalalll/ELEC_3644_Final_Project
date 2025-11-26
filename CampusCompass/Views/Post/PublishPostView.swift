import SwiftUI
import SwiftData
import PhotosUI

struct PublishPostView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    
    private var currentUser: User? {
        guard let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") else {
            return nil
        }
        
        let predicate = #Predicate<User> { user in
            user.username == currentUsername
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
        } catch {
            print("Failed to fetch current user: \(error)")
            return nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = currentUser {
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.username)
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text("Post to be published soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title（Optional）")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    TextField("", text: $title)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 120)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if content.isEmpty {
                                    Text("Share your life...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 23)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                .padding(.horizontal, 16)
                
                // 图片选择区域
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add photos")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(30)
                            .overlay(
                                Button {
                                    self.selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(8),
                                alignment: .topTrailing
                            )
                    } else {
                        Button {
                            isShowingImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo")
                                Text("Add photos")
                            }
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Publish Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Publish") {
                    publishPost()
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || currentUser == nil)
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .alert("Error", isPresented: .constant(currentUser == nil)) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Unable to get user information. Please log in again.")
        }
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func publishPost() {
        guard let user = currentUser else {
            print("No current user found")
            return
        }
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
        
        FirebaseService.shared.publishPost(
            title: trimmedTitle,
            content: trimmedContent,
            imageData: imageData,
            author: user
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    if let imageData = imageData {
                        post.postImage = imageData
                    }
                    
                    self.modelContext.insert(post)
                    user.posts.append(post)
                    
                    do {
                        try self.modelContext.save()
                        print("Post published successfully to Firebase by user: \(user.username)")
                        self.dismiss()
                    } catch {
                        print("Failed to save post locally: \(error)")
                        self.dismiss()
                    }
                    
                case .failure(let error):
                    print("Failed to publish post to Firebase: \(error)")
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationView {
        PublishPostView()
    }
    .modelContainer(for: [Post.self, User.self, PostComment.self])
}
