//
//  CameraKitView.swift
//  react-native-snapchat-camera-kit
//
//  Created by Rıdvan Altun on 25.03.2023.
//

import Foundation
import SCSDKCameraKit
import UIKit

public final class CameraKitView: UIView, CustomCameraControllerUIDelegate {
  // Props
  @objc var isActive = false
  @objc var preset: NSString?
  @objc var initialLens: NSDictionary?
  @objc var initialCameraFacing: NSString?
  @objc var torch: NSDictionary? {
    didSet {
      // TODO: handle back and ring light
      // ringLightView.ringLightGradient.updateIntensity(to: <#T##CGFloat#>, animated: <#T##Bool#>)
      // ringLightView.changeColor(to: <#T##UIColor#>)
    }
  }

  @objc var lensGroups: [String] = [] {
    didSet {
      cameraController?.groupIDs = lensGroups
    }
  }

  @objc var zoom: Bool = false {
    didSet {
      if zoom {
        isZoomConfigured = true
        setupZoomAction()
      }

      if !zoom && isZoomConfigured {
        isZoomConfigured = false
        removeZoomAction()
      }
    }
  }

  @objc var focus: Bool = false {
    didSet {
      if focus {
        isFocusConfigured = true
        setupTapToFocusAction()
      }

      if !focus && isFocusConfigured {
        isFocusConfigured = false
        removeTapToFocusAction()
      }
    }
  }

  // Events
  @objc var onInitialized: RCTDirectEventBlock?
  @objc var onLensChanged: RCTDirectEventBlock?
  @objc var onPhotoTaken: RCTBubblingEventBlock?
  @objc var onVideoRecordingFinished: RCTBubblingEventBlock?
  @objc var onError: RCTDirectEventBlock?

  // Internals

  public var cameraController: CustomCameraController?

  public var isZoomConfigured = false
  public var isFocusConfigured = false
  public var isInitialLensConfigured = false
  public var isPropsInitalized = false

  public var apiKey: String?
  public var nftId: String?
  public var collectionSlug: String?

  public var pinchGestureRecognizer: UIPinchGestureRecognizer?
  public var singleTap: UITapGestureRecognizer?

  public let previewView: PreviewView = {
    let view = PreviewView()
    view.clipsToBounds = true
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  public let ringLightView: RingLightView = {
    let view = RingLightView(frame: CGRect.zero)
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()

  required init(apiKey: String?, nftId: String?, collectionSlug: String?) {
    self.apiKey = apiKey
    self.nftId = nftId
    self.collectionSlug = collectionSlug

    super.init(frame: CGRect.zero)

    var sessionConfig: SessionConfig?

    if apiKey != nil {
      sessionConfig = SessionConfig(
        apiToken: apiKey! as String
      )
    }

    let errorHandler = CameraKitSessionErrorHandler { [weak self] error in
      self?.invokeOnError(CameraError.cameraKit(CameraKitError.core(message: error.description)))
    }

    cameraController = CustomCameraController(
      sessionConfig: sessionConfig,
      errorHandler: errorHandler,
      nftId: nftId,
      collectionSlug: collectionSlug
    )

    #if targetEnvironment(simulator)
      // TODO: invoke error fails
      invokeOnError(.device(.notAvailableOnSimulator))
      return
    #else
      setupView()
      setupRingLight()
    #endif
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public final func didSetProps(_ changedProps: [String]!) {
    if isPropsInitalized == false {
      let shouldPresetConfigured = changedProps.contains("preset")

      do {
        try setupCamera(preset: shouldPresetConfigured ? AVCaptureSession.Preset(withString: preset! as String) : .hd1280x720)
      } catch _ {
        // TODO: handle errors
      }

      isPropsInitalized = true
    }
  }

  final func applyInitialLens() {
    let initialLensId = initialLens?.value(forKey: "id")
    let launchData = initialLens?.value(forKey: "launchData")

    if initialLensId == nil {
      return
    }

    // swiftlint:disable force_cast
    applyLensById(lensId: initialLensId as! NSString, lensGroups: lensGroups as NSArray, launchDataMap: launchData as! NSDictionary?, promise: nil)
    // swiftlint:enable force_cast

    isInitialLensConfigured = true
  }
}
