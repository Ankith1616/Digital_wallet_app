package com.example.wallet_g

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class DigitalWalletWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.digital_wallet_widget)

            val title = widgetData.getString("widget_title", "Monthly Spending") ?: "Monthly Spending"
            val message = widgetData.getString("widget_message", "₹0") ?: "₹0"
            val chartPath = widgetData.getString("widget_chart", null)

            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_message, message)

            // Load chart image if available
            if (chartPath != null) {
                val file = File(chartPath)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(chartPath)
                    if (bitmap != null) {
                        views.setImageViewBitmap(R.id.widget_chart_image, bitmap)
                    }
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
