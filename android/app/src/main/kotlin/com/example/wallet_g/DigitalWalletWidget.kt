package com.example.wallet_g

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import java.io.File
import com.example.wallet_g.R

class DigitalWalletWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val packageName = context.packageName
        Log.d("DigitalWalletWidget", "onUpdate started for package: $packageName")
        
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(packageName, R.layout.digital_wallet_widget)
                
                val prefs = context.getSharedPreferences(
                    "HomeWidgetPreferences", Context.MODE_PRIVATE
                )
                
                val title = prefs.getString("widget_title", "Monthly Spending") ?: "Monthly Spending"
                val message = prefs.getString("widget_message", "--") ?: "--"
                
                views.setTextViewText(R.id.widget_title, title)
                views.setTextViewText(R.id.widget_message, message)

                // Load graph image with extreme safety
                val imagePath = prefs.getString("widget_chart", null)
                var imageLoaded = false
                if (imagePath != null) {
                    val file = File(imagePath)
                    if (file.exists() && file.length() > 0) {
                        try {
                            val options = BitmapFactory.Options().apply {
                                inJustDecodeBounds = true
                            }
                            BitmapFactory.decodeFile(imagePath, options)
                            
                            // Even smaller target size to stay safe on all devices
                            val targetWidth = 300
                            var inSampleSize = 1
                            if (options.outWidth > targetWidth) {
                                inSampleSize = options.outWidth / targetWidth
                            }
                            
                            val decodeOptions = BitmapFactory.Options().apply {
                                this.inSampleSize = inSampleSize
                                // Save memory by using 565 config (2 bytes per pixel)
                                inPreferredConfig = Bitmap.Config.RGB_565
                            }
                            
                            val bitmap = BitmapFactory.decodeFile(imagePath, decodeOptions)
                            if (bitmap != null) {
                                views.setImageViewBitmap(R.id.widget_chart_image, bitmap)
                                views.setViewVisibility(R.id.widget_chart_image, View.VISIBLE)
                                imageLoaded = true
                                Log.d("DigitalWalletWidget", "Bitmap loaded successfully: ${bitmap.width}x${bitmap.height}")
                            }
                        } catch (e: Exception) {
                            Log.e("DigitalWalletWidget", "Failed to load bitmap: ${e.message}")
                        }
                    } else {
                        Log.d("DigitalWalletWidget", "Image file does not exist or is empty: $imagePath")
                    }
                }
                
                if (!imageLoaded) {
                    views.setViewVisibility(R.id.widget_chart_image, View.GONE)
                }

                // Intent to open Insights Page
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    action = Intent.ACTION_VIEW
                    data = android.net.Uri.parse("digitalwallet://open?tab=insights")
                }
                
                val pendingIntent = PendingIntent.getActivity(
                    context, appWidgetId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d("DigitalWalletWidget", "Widget $appWidgetId updated successfully")
            } catch (e: Exception) {
                Log.e("DigitalWalletWidget", "Error in onUpdate for ID $appWidgetId: ${e.message}")
                try {
                    val fallbackViews = RemoteViews(packageName, R.layout.digital_wallet_widget)
                    fallbackViews.setTextViewText(R.id.widget_title, "Digital Wallet")
                    fallbackViews.setTextViewText(R.id.widget_message, "Tap to refresh")
                    fallbackViews.setViewVisibility(R.id.widget_chart_image, View.GONE)
                    appWidgetManager.updateAppWidget(appWidgetId, fallbackViews)
                } catch (e2: Exception) {
                    Log.e("DigitalWalletWidget", "Fallback failed: ${e2.message}")
                }
            }
        }
    }
}
