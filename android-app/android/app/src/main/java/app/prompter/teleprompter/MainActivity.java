package app.prompter.teleprompter;

import android.os.Bundle;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(AppUpdaterPlugin.class);   // in-app updater (see AppUpdaterPlugin.java)
        super.onCreate(savedInstanceState);
    }
}
