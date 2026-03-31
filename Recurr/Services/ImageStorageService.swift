import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

struct ImageStorageService {
    /// Maximum dimension for stored images
    private static let maxDimension: CGFloat = 200

    /// JPEG compression quality (0.0 - 1.0)
    private static let compressionQuality: CGFloat = 0.7

    // MARK: - Compression

    /// Compress an image to Data suitable for storage
    static func compress(image: PlatformImage) -> Data? {
        #if canImport(UIKit)
        return compressUIImage(image)
        #elseif canImport(AppKit)
        return compressNSImage(image)
        #endif
    }

    #if canImport(UIKit)
    private static func compressUIImage(_ image: UIImage) -> Data? {
        // Resize if needed
        let resized = resizeImage(image, maxDimension: maxDimension)

        // Compress to JPEG
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    #endif

    #if canImport(AppKit)
    private static func compressNSImage(_ image: NSImage) -> Data? {
        // Get the best representation
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Create a new resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        // Convert to JPEG data
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
    #endif

    // MARK: - Loading

    /// Load an image from Data
    static func loadImage(from data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }

    /// Convert stored Data to SwiftUI Image
    static func image(from data: Data?) -> Image? {
        guard let data = data,
              let platformImage = loadImage(from: data) else {
            return nil
        }

        #if canImport(UIKit)
        return Image(uiImage: platformImage)
        #elseif canImport(AppKit)
        return Image(nsImage: platformImage)
        #endif
    }
}

// MARK: - SwiftUI PhotosPicker Support

#if canImport(UIKit)
import PhotosUI

extension ImageStorageService {
    /// Load and compress image from PhotosPickerItem
    @MainActor
    static func loadFromPhotosPickerItem(_ item: PhotosPickerItem?) async -> Data? {
        guard let item = item else { return nil }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                return compress(image: image)
            }
        } catch {
            print("Error loading image: \(error)")
        }

        return nil
    }
}
#endif
