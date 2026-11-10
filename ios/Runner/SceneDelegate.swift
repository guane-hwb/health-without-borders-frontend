import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var privacyProtectionView: UIView?
  private var secureTextField: UITextField?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    setupScreenCaptureObserver()
    setupScreenshotObserver()
    applySecureLayer()
  }

  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showPrivacyProtectionView()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    checkAndHidePrivacyProtectionView()
  }

  private func setupScreenCaptureObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )
    if UIScreen.main.isCaptured {
      showPrivacyProtectionView()
    }
  }

  @objc private func screenCaptureChanged() {
    if UIScreen.main.isCaptured {
      showPrivacyProtectionView()
    } else {
      checkAndHidePrivacyProtectionView()
    }
  }

  private func setupScreenshotObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(userDidTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )
  }

  @objc private func userDidTakeScreenshot() {
    print("[SECURITY] Se detectó una captura de pantalla en el dispositivo.")
  }

  private func applySecureLayer() {
    guard secureTextField == nil, let window = self.window else { return }

    let field = UITextField()
    field.isSecureTextEntry = true
    field.translatesAutoresizingMaskIntoConstraints = false
    field.isUserInteractionEnabled = false

    window.addSubview(field)
    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: window.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: window.centerYAnchor)
    ])

    window.layer.superlayer?.addSublayer(field.layer)
    field.layer.sublayers?.first?.addSublayer(window.layer)
    secureTextField = field
  }

  private func showPrivacyProtectionView() {
    guard privacyProtectionView == nil, let window = self.window else { return }

    let view = UIView(frame: window.bounds)
    view.backgroundColor = UIColor(red: 235/255.0, green: 242/255.0, blue: 248/255.0, alpha: 1.0)
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let label = UILabel()
    label.text = "Salud sin Fronteras"
    label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
    label.textColor = UIColor(red: 26/255.0, green: 35/255.0, blue: 126/255.0, alpha: 1.0)
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])

    window.addSubview(view)
    privacyProtectionView = view
  }

  private func checkAndHidePrivacyProtectionView() {
    if !UIScreen.main.isCaptured {
      privacyProtectionView?.removeFromSuperview()
      privacyProtectionView = nil
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}