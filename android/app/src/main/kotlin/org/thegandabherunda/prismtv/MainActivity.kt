package org.thegandabherunda.prismtv

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Explicitly allow screenshots, screen recording, and casting (no FLAG_SECURE)
        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }
}

