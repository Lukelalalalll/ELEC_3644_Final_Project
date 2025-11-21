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
        ScrollView {
            VStack(spacing: 20) {
                // 标题输入区域
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title（Optioinal）")
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
                
                // 内容输入区域
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
                                        .padding(.vertical, 12)
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
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
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
    NavigationView {
        PublishPostView()
    }
    .modelContainer(for: [Post.self, User.self, PostComment.self])
}
