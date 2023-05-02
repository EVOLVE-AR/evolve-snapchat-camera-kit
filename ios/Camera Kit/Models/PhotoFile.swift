//
//  PhotoFile.swift
//  DemoApp
//
//  Created by Rıdvan Altun on 3.04.2023.
//

public final class PhotoFileModel {
  private var path: String
  
  init(path: String) {
    self.path = path
  }
  
  func toBridge() -> [String: Any] {
    return [
      "path": self.path,
    ]
  }
}
