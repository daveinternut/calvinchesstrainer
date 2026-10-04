package education.internut.calvinchesstrainer

import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        holdPhonesInPortrait(resources.configuration)
        super.onCreate(savedInstanceState)
    }

    // The manifest handles size changes itself (configChanges), so a foldable
    // opening or closing lands here rather than in a new onCreate.
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        holdPhonesInPortrait(newConfig)
    }

    // Phones stay portrait; tablets (smallest width 600 dp and up) rotate,
    // like iPad. Android 16 ignores orientation requests on large screens
    // for apps targeting API 36, which agrees with this.
    private fun holdPhonesInPortrait(config: Configuration) {
        val orientation =
            if (config.smallestScreenWidthDp < 600) {
                ActivityInfo.SCREEN_ORIENTATION_USER_PORTRAIT
            } else {
                ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
            }
        if (requestedOrientation != orientation) requestedOrientation = orientation
    }
}
