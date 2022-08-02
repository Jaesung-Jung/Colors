//
//  main.swift
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

enum Command: String, CaseIterable {
  case hex = "#"
  case rgb
  case srgb
  case p3
  case hsl
  case hsv
  case hsb
  case grayscale

  var multipliers: [Double] {
    switch self {
    case .rgb, .srgb, .p3:
      return [255, 255, 255, 100]
    case .hsl, .hsv, .hsb:
      return [360, 100, 100, 100]
    case .grayscale:
      return [255, 100]
    default:
      return []
    }
  }

  func representations(_ string: String) -> [ColorRepresentable] {
    let components = parseComponents(string)
    let color = parseColor(components)
    switch self {
    case .hex, .rgb, .srgb, .p3, .hsl, .hsv, .hsb, .grayscale:
      let usesAlphaComponents = components[safe: 3] != nil
      return [
        ColorLiteral(color: color),
        Hex(color: color, usesAlphaComponent: usesAlphaComponents),
        RGB(color: color, usesAlphaComponent: usesAlphaComponents, usesFraction: false),
        RGB(color: color, usesAlphaComponent: usesAlphaComponents, usesFraction: true),
        HSB(color: color, usesAlphaComponent: usesAlphaComponents, usesFraction: false),
        HSB(color: color, usesAlphaComponent: usesAlphaComponents, usesFraction: true)
      ]
    }
  }

  func parseColor(_ components: [CGFloat]) -> NSColor {
    switch self {
    case .hex, .rgb:
      return NSColor(
        deviceRed: components[safe: 0] ?? 0,
        green: components[safe: 1] ?? 0,
        blue: components[safe: 2] ?? 0,
        alpha: components[safe: 3] ?? 1
      )

    case .srgb:
      return NSColor(
        srgbRed: components[safe: 0] ?? 0,
        green: components[safe: 1] ?? 0,
        blue: components[safe: 2] ?? 0,
        alpha: components[safe: 3] ?? 1
      )

    case .p3:
      return NSColor(
        displayP3Red: components[safe: 0] ?? 0,
        green: components[safe: 1] ?? 0,
        blue: components[safe: 2] ?? 0,
        alpha: components[safe: 3] ?? 1
      )

    case .hsl, .hsv, .hsb:
      return NSColor(
        deviceHue: components[safe: 0] ?? 0,
        saturation: components[safe: 1] ?? 0,
        brightness: components[safe: 2] ?? 0,
        alpha: components[safe: 3] ?? 1
      )

    case .grayscale:
      return NSColor(
        deviceRed: components[safe: 0] ?? 0,
        green: components[safe: 0] ?? 0,
        blue: components[safe: 0] ?? 0,
        alpha: components[safe: 1] ?? 1
      )
    }
  }

  func parseComponents(_ string: String) -> [CGFloat] {
    switch self {
    case .hex:
      return string
        .replacingOccurrences(of: " ", with: "")
        .unfoldSubSequences(limitedTo: 2)
        .map { $0.padding(toLength: 2, withPad: "0", startingAt: 0) }
        .map { CGFloat(Int($0, radix: 16) ?? 0) / 255 }

    case .rgb, .srgb, .p3, .grayscale:
      return string
        .replacingOccurrences(of: ",", with: " ")
        .split(separator: " ")
        .enumerated()
        .compactMap { offset, component -> Double? in
          if component.contains(".") {
            return Double(component)
          } else {
            return Double(component).map { $0 / multipliers[offset] }
          }
        }
        .map { CGFloat($0) }

    case .hsl, .hsv, .hsb:
      return string
        .replacingOccurrences(of: ",", with: " ")
        .split(separator: " ")
        .enumerated()
        .compactMap { offset, component -> Double? in
          if component.contains(".") {
            return Double(component)
          } else {
            return Double(component).map { $0 / multipliers[offset] }
          }
        }
        .map { CGFloat($0) }
    }
  }
}

func sanitize(_ query: String) -> String {
  return query.lowercased()
    .trimmingCharacters(in: .whitespacesAndNewlines)
    .replacingOccurrences(of: "(", with: "")
    .replacingOccurrences(of: ")", with: "")
    .replacingOccurrences(of: "%", with: "")
    .replacingOccurrences(of: "-", with: ",")
}

func parse(_ query: String) -> [ColorRepresentable] {
  guard let command = Command.allCases.first(where: { query.hasPrefix($0.rawValue) }) else {
    return []
  }
  return command.representations(String(query.dropFirst(command.rawValue.count)))
}

// MARK: - MAIN

let query = CommandLine.arguments[1]
let items = parse(sanitize(query))
  .map { $0.item }

let res = Response(items: items)
print(try res.output())
