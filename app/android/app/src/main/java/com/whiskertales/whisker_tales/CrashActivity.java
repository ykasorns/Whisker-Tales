package com.whiskertales.whisker_tales;

import android.app.Activity;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.pm.PackageInfo;
import android.graphics.Typeface;
import android.os.Build;
import android.os.Bundle;
import android.util.TypedValue;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

/** Shows a crash report on screen (D-036). Plain framework views, no Flutter. */
public class CrashActivity extends Activity {
    @Override
    protected void onCreate(Bundle b) {
        super.onCreate(b);
        String version = "?";
        try {
            PackageInfo pi = getPackageManager().getPackageInfo(getPackageName(), 0);
            version = pi.versionName + " (" + pi.versionCode + ") updated " + pi.lastUpdateTime;
        } catch (Exception ignored) {
        }
        final String text = "Whisker Tales crashed\n"
                + getIntent().getStringExtra("title") + "\n"
                + "build " + version + "\n"
                + "Android " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ") "
                + Build.MANUFACTURER + " " + Build.MODEL + "\n\n"
                + getIntent().getStringExtra("detail");

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(24, 60, 24, 24);
        Button copy = new Button(this);
        copy.setText("Copy");
        copy.setOnClickListener(v -> ((ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE))
                .setPrimaryClip(ClipData.newPlainText("crash", text)));
        root.addView(copy);
        TextView t = new TextView(this);
        t.setText(text);
        t.setTypeface(Typeface.MONOSPACE);
        t.setTextSize(TypedValue.COMPLEX_UNIT_SP, 9);
        t.setTextIsSelectable(true);
        ScrollView sv = new ScrollView(this);
        sv.addView(t);
        root.addView(sv);
        setContentView(root);
    }
}
