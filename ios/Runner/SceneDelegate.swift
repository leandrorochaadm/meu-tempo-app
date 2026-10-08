import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  // App opened by a tap on the Live Activity: hand the URL to the tap stream
  // before Flutter sees it.
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    for context in connectionOptions.urlContexts {
      LockScreenTapStreamHandler.shared.offer(context.url)
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let rest = URLContexts.filter { !LockScreenTapStreamHandler.shared.offer($0.url) }
    if !rest.isEmpty {
      super.scene(scene, openURLContexts: rest)
    }
  }
}
