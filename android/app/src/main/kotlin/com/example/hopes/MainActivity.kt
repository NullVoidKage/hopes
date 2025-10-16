package com.example.hopes

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "native_file_opener"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
                    if (url != null) {
                        openFile(url, fileName, result)
                    } else {
                        result.error("INVALID_URL", "URL is null", null)
                    }
                }
                "openInBrowser" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        openInBrowser(url, result)
                    } else {
                        result.error("INVALID_URL", "URL is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openFile(url: String, fileName: String?, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.data = Uri.parse(url)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            
            // Add MIME type based on file extension
            val mimeType = getMimeType(fileName ?: "")
            if (mimeType.isNotEmpty()) {
                intent.type = mimeType
            }
            
            // Check if there's an app that can handle this intent
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                // Fallback: try to open in browser
                openInBrowser(url, result)
            }
        } catch (e: Exception) {
            result.error("OPEN_FAILED", "Failed to open file: ${e.message}", null)
        }
    }

    private fun openInBrowser(url: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW)
            intent.data = Uri.parse(url)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            
            // Check if there's an app that can handle this intent
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                result.success(true)
            } else {
                result.error("NO_BROWSER", "No browser app found", null)
            }
        } catch (e: Exception) {
            result.error("BROWSER_FAILED", "Failed to open in browser: ${e.message}", null)
        }
    }

    private fun getMimeType(fileName: String): String {
        return when (fileName.lowercase().substringAfterLast('.')) {
            "pdf" -> "application/pdf"
            "doc" -> "application/msword"
            "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "xls" -> "application/vnd.ms-excel"
            "xlsx" -> "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            "ppt" -> "application/vnd.ms-powerpoint"
            "pptx" -> "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "txt" -> "text/plain"
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "mp4" -> "video/mp4"
            "mp3" -> "audio/mpeg"
            else -> ""
        }
    }
}