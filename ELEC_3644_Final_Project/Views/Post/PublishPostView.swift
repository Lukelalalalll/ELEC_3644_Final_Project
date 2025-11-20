//
//  PublishPostView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//


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
    @State private var photosPickerItem: PhotosPickerItem?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("标题（可选）", text: $title)
                    TextField("分享你的想法...", text: $content, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section {
                    if let selectedImage = selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .cornerRadius(8)
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
                                Text("添加图片")
                            }
                            .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("添加图片")
                }
            }
            .navigationTitle("发布帖子")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("发布") {
                        publishPost()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }
    
    private func publishPost() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }
        
        let newPost = Post(
            postId: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            content: trimmedContent,
            postImage: selectedImage?.jpegData(compressionQuality: 0.8)
        )
        
        modelContext.insert(newPost)
        try? modelContext.save()
        
        dismiss()
    }
}

// MARK: - Image Picker
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
    PublishPostView()
        .modelContainer(for: [Post.self, User.self, PostComment.self])
}
