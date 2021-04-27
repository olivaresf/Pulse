//
//  AVCaptureDevice+Extensions.swift
//  Pulse
//
//  Created by Athanasios Papazoglou on 18/7/20.
//  Copyright © 2020 Athanasios Papazoglou. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    
    func updateFormatWithPreferredVideoSpec(preferredSpec: VideoSpec) {
        let availableFormats: [AVCaptureDevice.Format]
        if let preferredFps = preferredSpec.fps {
            availableFormats = availableFormatsFor(preferredFps: Float64(preferredFps))
        }
        else {
            availableFormats = formats
        }
        
        var selectedFormat: AVCaptureDevice.Format?
        if let preferredSize = preferredSpec.size {
            selectedFormat = formatFor(preferredSize: preferredSize, availableFormats: availableFormats)
        } else {
            selectedFormat = formatWithHighestResolution(availableFormats)
        }
        print("selected format: \(String(describing: selectedFormat))")
        
        if let selectedFormat = selectedFormat {
            do {
                try lockForConfiguration()
            }
            catch let error {
                fatalError(error.localizedDescription)
            }
            activeFormat = selectedFormat
            
            if let preferredFps = preferredSpec.fps {
                activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
                activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: preferredFps)
                unlockForConfiguration()
            }
        }
    }
    
    func toggleTorch(on: Bool) throws {
        guard hasTorch, isTorchAvailable else {
            throw TorchError.torchNotAvailable
        }
            try lockForConfiguration()
            torchMode = on ? .on : .off
            unlockForConfiguration()
    }
}

extension AVCaptureDevice {
    private func availableFormatsFor(preferredFps: Float64) -> [AVCaptureDevice.Format] {
        var availableFormats: [AVCaptureDevice.Format] = []
        availableFormats = formats.filter{ format  in
            let ranges = format.videoSupportedFrameRateRanges
            
            for range in ranges where range.minFrameRate <= preferredFps
                && preferredFps <= range.maxFrameRate {
                return true
            }
            
            return false
        }
        return availableFormats
    }
    
    private func formatWithHighestResolution(_ availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
        var maxWidth: Int32 = 0
        var selectedFormat: AVCaptureDevice.Format?
        availableFormats.forEach({ format in
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
            let width = dimensions.width
            if width >= maxWidth {
                maxWidth = width
                selectedFormat = format
            }
        })
        return selectedFormat
    }

    private func formatFor(preferredSize: CGSize, availableFormats: [AVCaptureDevice.Format]) -> AVCaptureDevice.Format? {
        for format in availableFormats {
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
            
            if dimensions.width >= Int32(preferredSize.width) && dimensions.height >= Int32(preferredSize.height) {
                return format
            }
        }
        
        return availableFormats.first { (format) -> Bool in
            let desc = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
            
            return dimensions.width >= Int32(preferredSize.width) && dimensions.height >= Int32(preferredSize.height)
        }
    }
}
enum TorchError: Error {
    case torchNotAvailable
}
