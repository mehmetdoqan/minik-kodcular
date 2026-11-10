# Minik Kodcular Android kabuğu (kaynak)

WebView kabuğu. Web uygulaması `app/src/main/assets/www/` içine kopyalanır (index.html, fonts/, ses/). Çevrimdışı sürümde Google Fonts yerine `fonts/fonts.css` + Baloo 2 woff2 dosyaları (npm @fontsource/baloo-2, latin + latin-ext, 500–800; css içindeki yollar fonts/ klasörüne göredir) kullanılır. SDK: platforms;android-34, build-tools;34.0.0. Derleme: `gradle assembleRelease --max-workers=1` (Maven 429 verirse tekrar dene; imza için apk/imza-anahtari-GIZLI.md). Sürüm yükseltirken `versionCode` artırılmalı.

Sürümler: 1.0 (versionCode 1, kayıp anahtar) · 1.1 (versionCode 2, 10 Kasım 2026): basık yatay ekranlar (yükseklik ≤ 600) için tek ekran düzeni — index.html'de 'Basık yatay ekranlar' bloğu; web sürümlerinde de var.

## settings.gradle
```
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "MinikKodcular"
include ':app'
```

## build.gradle
```
plugins {
    id 'com.android.application' version '8.7.3' apply false
}
```

## gradle.properties
```
org.gradle.jvmargs=-Xmx3g -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
```

## app/build.gradle
```
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.mehmetdogan.minikkodcular'
    compileSdk 34

    defaultConfig {
        applicationId 'com.mehmetdogan.minikkodcular'
        minSdk 24
        targetSdk 34
        versionCode 2
        versionName '1.1'
    }

    // Kalıcı imza: güncellemeler aynı anahtarla imzalanmalı, yoksa tablet güncellemeyi kabul etmez.
    signingConfigs {
        release {
            storeFile file(System.getenv('MK_KEYSTORE') ?: '../minikkodcular.jks')
            storePassword System.getenv('MK_STORE_PASS')
            keyAlias 'minikkodcular'
            keyPassword System.getenv('MK_STORE_PASS')
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.release
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    // Sesler zaten sıkıştırılmış; tekrar sıkıştırmak yükü artırır
    androidResources {
        noCompress 'mp3', 'woff2'
    }
}

dependencies {
    implementation 'androidx.webkit:webkit:1.8.0'
}
```

## app/src/main/AndroidManifest.xml
```
<?xml version="1.0" encoding="utf-8"?>
<!-- İnternet izni bilerek yok: uygulama hiçbir koşulda ağa çıkamaz. -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="false"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme"
        android:hardwareAccelerated="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="sensorLandscape"
            android:configChanges="orientation|screenSize|screenLayout|keyboardHidden|keyboard|smallestScreenSize|uiMode|density|fontScale"
            android:launchMode="singleTask">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

## app/src/main/res/values/strings.xml
```
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Minik Kodcular</string>
</resources>
```

## app/src/main/res/values/styles.xml
```
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:Theme.Material.Light.NoActionBar.Fullscreen">
        <item name="android:windowBackground">@android:color/white</item>
        <item name="android:statusBarColor">#EAF0FA</item>
        <item name="android:navigationBarColor">#EAF0FA</item>
    </style>
</resources>
```

## app/src/main/java/com/mehmetdogan/minikkodcular/MainActivity.java
```
package com.mehmetdogan.minikkodcular;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.webkit.WebViewAssetLoader;

/**
 * Minik Kodcular: uygulamanın tamamı (oyunlar, yazı tipi, Emel sesleri) assets/www içinde.
 * Sayfa https://appassets.androidplatform.net/assets/www/ adresinden, cihazın içinden yüklenir;
 * uygulamanın internet izni yoktur ve bu adres dışındaki her istek engellenir.
 */
public class MainActivity extends Activity {
    private static final String HOST = "appassets.androidplatform.net";
    private static final String START = "https://" + HOST + "/assets/www/index.html";
    private WebView web;

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        final WebViewAssetLoader loader = new WebViewAssetLoader.Builder()
                .setDomain(HOST)
                .addPathHandler("/assets/", new WebViewAssetLoader.AssetsPathHandler(this))
                .build();

        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);                 // ilerleme ve ayarlar (localStorage)
        s.setMediaPlaybackRequiresUserGesture(false); // yönergeler dokunmadan da seslendirilsin
        s.setTextZoom(100);                           // tabletin yazı boyutu ayarı düzeni bozmasın
        s.setAllowFileAccess(false);
        s.setAllowContentAccess(false);
        s.setSupportZoom(false);
        s.setBuiltInZoomControls(false);
        web.setOverScrollMode(View.OVER_SCROLL_NEVER);
        web.setLongClickable(false);
        web.setOnLongClickListener(v -> true);        // uzun basınca metin seçimi/menü çıkmasın
        web.setBackgroundColor(0xFFEAF0FA);

        web.setWebViewClient(new WebViewClient() {
            @Override
            public WebResourceResponse shouldInterceptRequest(WebView view, WebResourceRequest req) {
                Uri u = req.getUrl();
                if (HOST.equals(u.getHost())) return loader.shouldInterceptRequest(u);
                return new WebResourceResponse("text/plain", "utf-8", 403, "Engellendi", null, null);
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest req) {
                return !HOST.equals(req.getUrl().getHost()); // dış bağlantılar açılmaz
            }
        });

        setContentView(web);
        hideBars();
        if (savedInstanceState != null) web.restoreState(savedInstanceState);
        else web.loadUrl(START);
    }

    @SuppressWarnings("deprecation")
    private void hideBars() {
        web.setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) hideBars();
    }

    // Geri tuşu: oyundaysa ana menüye döner; ana menüde bir şey yapmaz (çocuk yanlışlıkla çıkmasın).
    @SuppressWarnings("deprecation")
    @Override
    public void onBackPressed() {
        web.evaluateJavascript(
                "(function(){var h=location.hash;if(h&&h!=='#'&&h!=='#menu'){location.hash='#menu';return 1;}return 0;})()",
                null);
    }

    @Override
    protected void onPause() {
        super.onPause();
        web.evaluateJavascript("window.mkHush&&window.mkHush()", null);
        web.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        web.onResume();
        hideBars();
    }

    @Override
    protected void onSaveInstanceState(Bundle out) {
        super.onSaveInstanceState(out);
        web.saveState(out);
    }
}
```
