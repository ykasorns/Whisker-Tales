package com.whiskertales.whisker_tales;

import android.app.ActivityManager;
import android.app.Application;
import android.app.ApplicationExitInfo;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Process;

import java.io.InputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.util.List;

/**
 * Test-build crash reporter (D-036). The app died at launch on a phone with no
 * way to read logcat, so this shows the crash on screen: a Java crash is caught
 * here (installed in attachBaseContext, i.e. before any content provider such
 * as the ads SDK starts); a native crash is read from the system's exit
 * reasons on the next launch. Both open {@link CrashActivity}, which runs in
 * its own process so it works even when the main process is broken.
 *
 * Remove (or replace with a friendly message) before a Play release.
 */
public class WtApp extends Application {
    static final String PREFS = "wt_crash";

    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);
        final Context app = base;
        Thread.setDefaultUncaughtExceptionHandler((thread, error) -> {
            try {
                StringWriter sw = new StringWriter();
                error.printStackTrace(new PrintWriter(sw));
                show(app, "Java crash on thread \"" + thread.getName() + "\"", sw.toString());
            } catch (Throwable ignored) {
                // nothing more we can do
            }
            Process.killProcess(Process.myPid());
            System.exit(10);
        });
    }

    @Override
    public void onCreate() {
        super.onCreate();
        if (Build.VERSION.SDK_INT >= 30 && !getProcessName().contains(":")) {
            try {
                reportLastExit();
            } catch (Throwable ignored) {
                // diagnostics must never break launch
            }
        }
    }

    private void reportLastExit() throws Exception {
        ActivityManager am = (ActivityManager) getSystemService(Context.ACTIVITY_SERVICE);
        List<ApplicationExitInfo> list = am.getHistoricalProcessExitReasons(null, 0, 1);
        if (list.isEmpty()) return;
        ApplicationExitInfo e = list.get(0);
        SharedPreferences p = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (e.getTimestamp() <= p.getLong("shown", 0)) return;
        int r = e.getReason();
        // Android reclaims background apps for memory all the time: that is
        // not a crash of ours (importance 400 = it was cached, not in use)
        if ((r == ApplicationExitInfo.REASON_LOW_MEMORY
                || r == ApplicationExitInfo.REASON_SIGNALED)
                && e.getImportance() >= ActivityManager.RunningAppProcessInfo.IMPORTANCE_CACHED) {
            return;
        }
        if (r != ApplicationExitInfo.REASON_CRASH_NATIVE
                && r != ApplicationExitInfo.REASON_SIGNALED
                && r != ApplicationExitInfo.REASON_INITIALIZATION_FAILURE
                && r != ApplicationExitInfo.REASON_ANR
                && r != ApplicationExitInfo.REASON_LOW_MEMORY) {
            return; // user swipes, normal exits and our own Java crashes (already shown)
        }
        p.edit().putLong("shown", e.getTimestamp()).apply();
        StringBuilder sb = new StringBuilder();
        sb.append("reason=").append(r).append(" status=").append(e.getStatus())
                .append("\ndescription=").append(e.getDescription())
                .append("\nimportance=").append(e.getImportance()).append("\n");
        if (r == ApplicationExitInfo.REASON_CRASH_NATIVE) {
            try (InputStream in = e.getTraceInputStream()) {
                if (in != null) sb.append("\n--- native trace (printable strings) ---\n")
                        .append(printable(in, 24000));
            }
        }
        show(this, "Native crash / abnormal exit on the previous launch", sb.toString());
    }

    /** The tombstone is a protobuf: keep the readable runs (library, function names). */
    private static String printable(InputStream in, int max) throws Exception {
        byte[] buf = new byte[max];
        int n = 0, k;
        while (n < max && (k = in.read(buf, n, max - n)) > 0) n += k;
        StringBuilder out = new StringBuilder(), run = new StringBuilder();
        for (int i = 0; i < n; i++) {
            char c = (char) (buf[i] & 0xff);
            if (c >= 32 && c < 127) {
                run.append(c);
            } else {
                if (run.length() >= 5) out.append(run).append('\n');
                run.setLength(0);
            }
        }
        if (run.length() >= 5) out.append(run).append('\n');
        return out.toString();
    }

    static void show(Context ctx, String title, String detail) {
        Intent i = new Intent(ctx, CrashActivity.class)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK)
                .putExtra("title", title)
                .putExtra("detail", detail);
        ctx.startActivity(i);
    }
}
