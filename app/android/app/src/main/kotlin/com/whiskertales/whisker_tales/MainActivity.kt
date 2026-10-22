package com.whiskertales.whisker_tales

import android.os.Bundle
import com.google.android.gms.games.PlayGamesSdk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /** Play Games is only started when a project id was set at build time
     *  (T-023, D-025); without one the game never touches it. */
    private var playGames = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val id = getString(R.string.game_services_project_id)
        if (id.isNotBlank()) {
            PlayGamesSdk.initialize(this)
            playGames = true
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "whisker_tales/play_games")
            .setMethodCallHandler { call, result ->
                if (call.method == "enabled") result.success(playGames)
                else result.notImplemented()
            }
    }
}
