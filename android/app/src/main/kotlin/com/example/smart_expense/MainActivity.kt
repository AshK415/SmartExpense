package com.example.smart_expense

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
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

    private lateinit var mResult: Result
    private var requestCodeNumber = 201119

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Unit {
        if (requestCodeNumber == requestCode && mResult != null) {
            if (data != null) {
                try {
                    val response = data.getStringExtra("response")!!
                    this.mResult?.success(response)
                } catch (ex: Exception) {
                    this.mResult?.error("invalid_response", ex.toString(),null)
                }
            } else {
                this.mResult?.success("user_cancelled")
            }
        }
        return;
    }


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
                        //val appName = it.activityInfo.nonLocalizedLabel?.toString()
                        val appName = getPackageManager()?.getApplicationLabel(getPackageManager()?.getApplicationInfo(packageName, PackageManager.GET_META_DATA)!!)
                        mapOf("packageName" to packageName, "icon" to icon, "appName" to appName!!)
                    }
                    result.success(activityResponse)
                } catch(ex: Exception){
                    Log.e("UPIPAY", ex.message!!)
                    result.error("Check the issue",ex.message!!,400)
                }
                
             }
             else if(call.method=="initiateTransaction"){
                mResult = result
                val app = call.argument("package") ?: ""
                val url = call.argument("url") ?: ""
                try{
                    val uri = Uri.parse(url)
                    val intent = Intent(Intent.ACTION_VIEW, uri)
                    intent.setPackage(app)
                    if(intent.resolveActivity(getPackageManager()!!)==null){
                        result.error("Check the issue", "Activity Unavailable", 400)
                    }
                    getActivity()?.startActivityForResult(intent, requestCodeNumber)
                    //result.success("Done")
                } catch(ex: Exception){
                    Log.e("UPIPAY", ex.toString())
                    result.error("Check the issue", ex.toString(), 400)
                }
             }
             else{
                result.notImplemented()
             }
        }
    }
}
