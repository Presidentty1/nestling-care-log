import SwiftUI
import PhotosUI

/// Component for selecting and displaying photos attached to events
struct PhotoPickerView: View {
    @Binding var selectedPhotos: [UIImage]
    let maxPhotos: Int = 3

    @State private var showPhotoPicker = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            // Header with add button
            HStack {
                Text("Photos")
                    .font(.headline)

                Spacer()

                if selectedPhotos.count < maxPhotos {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxPhotos - selectedPhotos.count,
                        matching: .images
                    ) {
                        HStack(spacing: .spacingXS) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.primary)
                            Text("Add Photo")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, .spacingXS)
                        .padding(.horizontal, .spacingSM)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(.radiusMD)
                    }
                }
            }

            // Photo thumbnails
            if !selectedPhotos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: .spacingSM) {
                        ForEach(selectedPhotos.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedPhotos[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(.radiusMD)
                                    .clipped()

                                // Remove button
                                Button(action: {
                                    selectedPhotos.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                        .font(.system(size: 16))
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.vertical, .spacingXS)
                }
            }

            // Photo count indicator
            if selectedPhotos.count > 0 {
                Text("\(selectedPhotos.count) of \(maxPhotos) photos")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
        }
        .onChange(of: selectedItems) { _, newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedPhotos.append(image)
                    }
                }
                selectedItems.removeAll()
            }
        }
    }
}

#Preview {
    PhotoPickerView(selectedPhotos: .constant([]))
        .padding()
}

