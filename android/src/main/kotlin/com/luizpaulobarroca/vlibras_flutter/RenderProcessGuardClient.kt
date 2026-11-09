package com.luizpaulobarroca.vlibras_flutter

import android.annotation.TargetApi
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Build
import android.os.Message
import android.util.Log
import android.view.KeyEvent
import android.webkit.ClientCertRequest
import android.webkit.HttpAuthHandler
import android.webkit.RenderProcessGoneDetail
import android.webkit.SafeBrowsingResponse
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient

/**
 * WebViewClient que repassa tudo ao client original (o do webview_flutter) e
 * só acrescenta o tratamento de [onRenderProcessGone].
 *
 * Retornar true em onRenderProcessGone impede o Chromium de encerrar o app. O
 * WebView afetado não pode mais ser usado: [onGone] avisa o Dart, que descarta
 * esse WebView e cria outro.
 *
 * Os parâmetros são anuláveis de propósito: o Kotlin derruba o app se o
 * framework passar null num parâmetro declarado como não nulo.
 */
@TargetApi(Build.VERSION_CODES.O)
@Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
internal class RenderProcessGuardClient(
    private val delegate: WebViewClient,
    private val onGone: (didCrash: Boolean) -> Unit,
) : WebViewClient() {

    override fun onRenderProcessGone(view: WebView?, detail: RenderProcessGoneDetail?): Boolean {
        val didCrash = detail?.didCrash() ?: false
        Log.w(TAG, "Renderer do WebView encerrado (didCrash=$didCrash)")
        // Não repassa ao delegate: o client do webview_flutter não trata o
        // evento e devolveria false, o que encerraria o app.
        onGone(didCrash)
        return true
    }

    override fun shouldOverrideUrlLoading(view: WebView?, url: String?): Boolean =
        delegate.shouldOverrideUrlLoading(view, url)

    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean =
        delegate.shouldOverrideUrlLoading(view, request)

    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) =
        delegate.onPageStarted(view, url, favicon)

    override fun onPageFinished(view: WebView?, url: String?) =
        delegate.onPageFinished(view, url)

    override fun onLoadResource(view: WebView?, url: String?) =
        delegate.onLoadResource(view, url)

    override fun onPageCommitVisible(view: WebView?, url: String?) =
        delegate.onPageCommitVisible(view, url)

    override fun shouldInterceptRequest(view: WebView?, url: String?): WebResourceResponse? =
        delegate.shouldInterceptRequest(view, url)

    override fun shouldInterceptRequest(
        view: WebView?,
        request: WebResourceRequest?,
    ): WebResourceResponse? = delegate.shouldInterceptRequest(view, request)

    override fun onTooManyRedirects(view: WebView?, cancelMsg: Message?, continueMsg: Message?) =
        delegate.onTooManyRedirects(view, cancelMsg, continueMsg)

    override fun onReceivedError(
        view: WebView?,
        errorCode: Int,
        description: String?,
        failingUrl: String?,
    ) = delegate.onReceivedError(view, errorCode, description, failingUrl)

    override fun onReceivedError(
        view: WebView?,
        request: WebResourceRequest?,
        error: WebResourceError?,
    ) = delegate.onReceivedError(view, request, error)

    override fun onReceivedHttpError(
        view: WebView?,
        request: WebResourceRequest?,
        errorResponse: WebResourceResponse?,
    ) = delegate.onReceivedHttpError(view, request, errorResponse)

    override fun onFormResubmission(view: WebView?, dontResend: Message?, resend: Message?) =
        delegate.onFormResubmission(view, dontResend, resend)

    override fun doUpdateVisitedHistory(view: WebView?, url: String?, isReload: Boolean) =
        delegate.doUpdateVisitedHistory(view, url, isReload)

    override fun onReceivedSslError(view: WebView?, handler: SslErrorHandler?, error: SslError?) =
        delegate.onReceivedSslError(view, handler, error)

    override fun onReceivedClientCertRequest(view: WebView?, request: ClientCertRequest?) =
        delegate.onReceivedClientCertRequest(view, request)

    override fun onReceivedHttpAuthRequest(
        view: WebView?,
        handler: HttpAuthHandler?,
        host: String?,
        realm: String?,
    ) = delegate.onReceivedHttpAuthRequest(view, handler, host, realm)

    override fun shouldOverrideKeyEvent(view: WebView?, event: KeyEvent?): Boolean =
        delegate.shouldOverrideKeyEvent(view, event)

    override fun onUnhandledKeyEvent(view: WebView?, event: KeyEvent?) =
        delegate.onUnhandledKeyEvent(view, event)

    override fun onScaleChanged(view: WebView?, oldScale: Float, newScale: Float) =
        delegate.onScaleChanged(view, oldScale, newScale)

    override fun onReceivedLoginRequest(
        view: WebView?,
        realm: String?,
        account: String?,
        args: String?,
    ) = delegate.onReceivedLoginRequest(view, realm, account, args)

    @TargetApi(Build.VERSION_CODES.O_MR1)
    override fun onSafeBrowsingHit(
        view: WebView?,
        request: WebResourceRequest?,
        threatType: Int,
        callback: SafeBrowsingResponse?,
    ) = delegate.onSafeBrowsingHit(view, request, threatType, callback)

    private companion object {
        const val TAG = "VLibrasFlutter"
    }
}
