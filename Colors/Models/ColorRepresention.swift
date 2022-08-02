//
//  ColorRepresention.swift
//
//  Copyright © 2022 Jaesung Jung. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import AppKit
import Alfred

// MARK: - ColorRepresentable

protocol ColorRepresentable: ItemRepresentable, CustomStringConvertible {
  var color: NSColor { get }

  var baseComponents: [CGFloat] { get }

  var usesAlphaComponent: Bool { get }
  var usesFraction: Bool { get }

  var separator: String { get }

  var componentsString: String { get }
}

extension ColorRepresentable {
  var colorComponents: [CGFloat] {
    return usesAlphaComponent ? baseComponents + [color.alphaComponent] : baseComponents
  }

  var separator: String { ", " }

  var icon: Icon? {
    guard let cacheURL = Environment.workflowCacheDir.map({ URL(fileURLWithPath: $0) }) else {
      return nil
    }

    let components = [color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent]
    let name = components.map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
    let url = cacheURL.appendingPathComponent("\(name).jpg")

    guard !FileManager.default.fileExists(atPath: url.path) else {
      return Icon(path: url.path)
    }

    guard let jpegData = NSImage(color: color).jpegData(compressionQuality: 1) else {
      return nil
    }
    do {
      if !FileManager.default.fileExists(atPath: cacheURL.path) {
        try FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
      }
      try jpegData.write(to: url)
      return Icon(path: url.path)
    } catch {
      return nil
    }
  }

  var item: Item {
    return Item(
      title: description,
      subtitle: String(describing: Self.self),
      arg: .simple(componentsString),
      icon: icon
    )
  }
}

// MARK: - Hex

struct Hex: ColorRepresentable {
  let color: NSColor

  var baseComponents: [CGFloat] {
    return [color.redComponent, color.greenComponent, color.blueComponent]
  }

  let usesAlphaComponent: Bool
  var usesFraction: Bool { false }

  var separator: String { "" }

  var componentsString: String {
    let hexValue: (CGFloat) -> String = {
      return String(format: "%02X", Int(($0 * 255).rounded()))
    }
    return colorComponents.map(hexValue).joined(separator: separator)
  }

  var description: String {
    return "#\(componentsString)"
  }
}

// MARK: - RGB

struct RGB: ColorRepresentable {
  let color: NSColor

  var baseComponents: [CGFloat] {
    return [color.redComponent, color.greenComponent, color.blueComponent]
  }

  let usesAlphaComponent: Bool
  let usesFraction: Bool

  var componentsString: String {
    if usesFraction {
      return colorComponents.map { "\($0)" }.joined(separator: separator)
    } else {
      let multipliers: [CGFloat] = [255, 255, 255, 100]
      let intValue: (Int, CGFloat) -> String = { offset, value in
        return "\(Int((value * multipliers[offset]).rounded()))"
      }
      return colorComponents.enumerated().map(intValue).joined(separator: separator)
    }
  }

  var description: String {
    if usesAlphaComponent {
      return "RGBA(\(componentsString))"
    } else {
      return "RGB(\(componentsString))"
    }
  }
}

// MARK: - HSB

struct HSB: ColorRepresentable {
  let color: NSColor

  var baseComponents: [CGFloat] {
    return [color.hueComponent, color.saturationComponent, color.brightnessComponent]
  }

  let usesAlphaComponent: Bool
  let usesFraction: Bool

  var componentsString: String {
    if usesFraction {
      return colorComponents.map { "\($0)" }.joined(separator: separator)
    } else {
      let multipliers: [CGFloat] = [360, 100, 100, 100]
      let intValue: ((offset: Int, element: CGFloat)) -> String = {
        return "\(Int(($0.element * multipliers[$0.offset]).rounded()))"
      }
      return colorComponents.enumerated().map(intValue).joined(separator: separator)
    }
  }

  var description: String {
    if usesAlphaComponent {
      return "HSBA(\(componentsString))"
    } else {
      return "HSB(\(componentsString))"
    }
  }
}

// MARK: - ColorLiteral

struct ColorLiteral: ColorRepresentable {
  var color: NSColor

  let baseComponents: [CGFloat] = []

  var usesAlphaComponent: Bool { true }
  var usesFraction: Bool { true }

  var componentsString: String {
    return "#colorLiteral(red: \(color.redComponent), green: \(color.greenComponent), blue: \(color.blueComponent), alpha: \(color.alphaComponent))"
  }

  var description: String {
    return "Swift Color Literal"
  }
}
