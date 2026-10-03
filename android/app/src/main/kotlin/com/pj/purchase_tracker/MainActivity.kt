package com.pj.purchase_tracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.pj.purchase_tracker/file_picker"
        private const val SAVE_FILE_REQUEST_CODE = 1001
        private const val PICK_FILE_REQUEST_CODE = 1002
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingFileContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "Purchase_Tracker_Backup.json"
                    val content = call.argument<String>("content") ?: ""

                    pendingResult = result
                    pendingFileContent = content

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    startActivityForResult(intent, SAVE_FILE_REQUEST_CODE)
                }
                "pickJsonFile" -> {
                    pendingResult = result

                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "*/*"))
                    }
                    startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == SAVE_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri: Uri = data.data!!
                try {
                    contentResolver.openOutputStream(uri)?.use { outputStream ->
                        OutputStreamWriter(outputStream).use { writer ->
                            writer.write(pendingFileContent ?: "")
                        }
                    }
                    pendingResult?.success(uri.toString())
                } catch (e: Exception) {
                    pendingResult?.error("SAVE_FAILED", e.message, null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
            pendingFileContent = null
        } else if (requestCode == PICK_FILE_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val uri: Uri = data.data!!
                try {
                    val stringBuilder = StringBuilder()
                    contentResolver.openInputStream(uri)?.use { inputStream ->
                        BufferedReader(InputStreamReader(inputStream)).use { reader ->
                            var line: String? = reader.readLine()
                            while (line != null) {
                                stringBuilder.append(line).append("\n")
                                line = reader.readLine()
                            }
                        }
                    }
                    pendingResult?.success(stringBuilder.toString())
                } catch (e: Exception) {
                    pendingResult?.error("READ_FAILED", e.message, null)
                }
            } else {
                pendingResult?.success(null)
            }
            pendingResult = null
        }
    }
}
