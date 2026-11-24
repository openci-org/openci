package org.openci.workersmoke;

import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;

public final class SmokeActivity extends Activity {
    Button button;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        setShowWhenLocked(true);
        setTurnScreenOn(true);
        button = new Button(this);
        button.setText("Tap to verify");
        button.setOnClickListener(view -> button.setText("Tap received"));
        setContentView(button);
    }
}
