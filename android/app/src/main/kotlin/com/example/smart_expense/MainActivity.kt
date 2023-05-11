package com.example.smart_expense

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.Uri
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.Log
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fun encodeToBase64(image: Bitmap): String? {
            val byteArrayOS = ByteArrayOutputStream()
            image.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOS)
            return Base64.encodeToString(byteArrayOS.toByteArray(), Base64.NO_WRAP)
        }

        fun getBitmapFromDrawable(drawable: Drawable): Bitmap? {
            val bmp: Bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight())
            drawable.draw(canvas)
            return bmp
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "example.com/channel").setMethodCallHandler {
            call, result ->
             if(call.method =="getApps") {
                val uriBuilder = Uri.Builder()
                uriBuilder.scheme("upi").authority("pay")
                val uri = uriBuilder.build()
                val intent = Intent(Intent.ACTION_VIEW, uri)
                try {
                    val activities = getPackageManager()?.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    val activityResponse = activities?.map{
                        val packageName = it.activityInfo.packageName
                        val drawable = getPackageManager()?.getApplicationIcon(packageName)
                        val bitmap = getBitmapFromDrawable(drawable!!)
                        val icon = if (bitmap != null) {
                          encodeToBase64(bitmap)
                        } else {
                           null
                        }
                        val appName = it.activityInfo.nonLocalizedLabel.toString()

                        mapOf("packageName" to packageName, "icon" to icon, "appName" to appName)
                    }
                    result.success(activityResponse)
                } catch(ex: Exception){
                    //Log.d("MainActivity", ex)
                    result.error("error occured", "Check the issue", null)
                }
                
             }
             else{
                result.notImplemented()
             }
        }
    }
}
