package org.openci.workersmoke;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Intent;
import android.graphics.Point;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.InputDevice;
import android.view.MotionEvent;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;

public final class SmokeInstrumentation extends Instrumentation {
    @Override
    public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        start();
    }

    @Override
    public void onStart() {
        Bundle result = new Bundle();
        try {
            Intent launch = new Intent(getTargetContext(), SmokeActivity.class);
            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            SmokeActivity activity = (SmokeActivity) startActivitySync(launch);
            verifyTouch(activity);
            result.putString("openci", "BUTTON_TAPPED");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable failure) {
            result.putString("openci", failure.toString());
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private void verifyTouch(SmokeActivity activity) {
        AtomicReference<Point> center = new AtomicReference<>();
        AtomicBoolean tapped = new AtomicBoolean();
        for (int attempt = 0; attempt < 25; attempt++) {
            center.set(null);
            runOnMainSync(() -> {
                if (activity.hasWindowFocus() && activity.button.isShown()
                        && activity.button.getWidth() > 0 && activity.button.getHeight() > 0) {
                    int[] xy = new int[2];
                    activity.button.getLocationOnScreen(xy);
                    center.set(new Point(xy[0] + activity.button.getWidth() / 2,
                            xy[1] + activity.button.getHeight() / 2));
                }
            });
            if (center.get() != null) {
                long down = SystemClock.uptimeMillis();
                sendTouch(down, MotionEvent.ACTION_DOWN, center.get());
                SystemClock.sleep(75);
                sendTouch(down, MotionEvent.ACTION_UP, center.get());
                waitForIdleSync();
                runOnMainSync(() -> tapped.set("Tap received".contentEquals(activity.button.getText())));
                if (tapped.get()) {
                    return;
                }
            }
            SystemClock.sleep(500);
        }
        throw new AssertionError("The button did not receive the touchscreen event");
    }

    private void sendTouch(long down, int action, Point point) {
        MotionEvent event = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action,
                point.x, point.y, 0);
        try {
            event.setSource(InputDevice.SOURCE_TOUCHSCREEN);
            getUiAutomation().injectInputEvent(event, true);
        } finally {
            event.recycle();
        }
    }
}
