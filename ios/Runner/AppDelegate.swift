private var privacyProtectionView: UIView?

  override func applicationWillResignActive(_ application: UIApplication) {
    super.applicationWillResignActive(application)
    showPrivacyProtectionView()
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    checkAndHidePrivacyProtectionView()
  }

  private func showPrivacyProtectionView() {
    guard privacyProtectionView == nil, let window = self.window else { return }

    let view = UIView(frame: window.bounds)
    view.backgroundColor = UIColor(red: 235/255.0, green: 242/255.0, blue: 248/255.0, alpha: 1.0)
    view.autoresizingMask = UIView.AutoresizingMask([.flexibleWidth, .flexibleHeight])

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