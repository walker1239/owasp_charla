package com.pragma.vulnbank.vuln_bank

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    // [fix/M6] Bloquea capturas de pantalla y la vista previa en "Recientes",
    // protegiendo datos sensibles (saldos, tarjetas, PII) en pantalla.
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
