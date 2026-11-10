//
//  ImageFileManager.swift
//  MyRoadWay
//

import UIKit

enum ImageFileManager {
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 이미지를 앱 Documents 디렉터리에 JPEG 형식으로 저장합니다.
    static func saveImage(_ image: UIImage, fileName: String) throws {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(
                domain: "ImageFileManager",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "이미지 데이터 압축에 실패했습니다."]
            )
        }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// 파일명으로 앱 Documents 디렉터리에서 이미지를 불러옵니다.
    static func loadImage(fileName: String) -> UIImage? {
        guard !fileName.isEmpty else { return nil }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// 파일명에 해당하는 이미지를 디스크에서 삭제합니다.
    static func deleteImage(fileName: String) {
        guard !fileName.isEmpty else { return }
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
