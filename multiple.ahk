#Persistent
CoordMode, Mouse, Screen
EnvGet, userProfile, USERPROFILE
SetWorkingDir, %A_ScriptDir%

; ///////////////////////////////////////// Variables de config globales /////////////////////////////////////////
global contadorComentariosHechos := 167 ; Comentarios YA hechos
global limiteDiario := 500 ; Cantidad máxima de comentarios a enviar
global cantMenciones := 2 ; Cantidad de cuentas a mecionar por comentario
global intervaloMinutos, intervaloSegundos, intervalo
global totalComentarios := 6722 ; Cantidad de comentarios totales que tiene la publicación
global tiempoRestante := 0
global timerActivo := false

; ///////////////////////////////////////// Crear GUI una vez /////////////////////////////////////////
Gui, TimerGUI:+AlwaysOnTop -Caption +ToolWindow
Gui, TimerGUI:Font, s14 Bold, Segoe UI
Gui, TimerGUI:Add, Text, vTiempoRestanteText w200 Center, Esperando...
Gui, TimerGUI:Show, x10 y10 NoActivate, Timer Visual


; ///////////////////////////////////////// Set del Timer Inicial /////////////////////////////////////////
Comenzar:
    Random, intervaloMinutos, 2, 4 ; Entre x e y minutos
    Random, intervaloSegundos, 0, 59
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    SetTimer, ActualizarTimerVisual, 1000
    SetTimer, Comentar, %intervalo%
Return

Comentar:
if (contadorComentariosHechos >= limiteDiario) {
    TrayTip, AutoHotkey, Límite diario alcanzado (%limiteDiario% comentarios), 5
    SetTimer, Comentar, Off
    SetTimer, ActualizarTimerVisual, Off
    GuiControl, TimerGUI:, TiempoRestanteText, Límite alcanzado!
    Return
}

; ///////////////////////////////////////// Creación del mensaje /////////////////////////////////////////
cuentas := SeleccionarCuentas(A_ScriptDir . "\cuentas.txt")
If (cuentas != "") {
    emoji := SeleccionarEmoji()
    frase := SeleccionarFrase()
    If (RandomDecision(50)) ; chance de no poner emoji
        emoji := ""
    If (RandomDecision(50)) ; chance de no poner frase
        frase := ""

    mensaje := cuentas " " frase " " emoji 
    mensaje := Trim(mensaje)

    WinActivate, ahk_exe opera.exe
    WinWaitActive, ahk_exe opera.exe,, 3
    If !WinActive("ahk_exe opera.exe") {
        MsgBox, No pude activar la ventana de Opera
        Return
    }

    Sleep 500
    MouseMove, 980, 960 ; Coords del input text
    Sleep 200
    Click left
    Sleep 500
    SendInput %mensaje% ; Enviar Mensaje 
    Sleep 500
    SendInput {Enter}
    Sleep 500
    MouseClick, left, 1300, 960 ; Coords del boton publicar y publicación del comentario
    Sleep 2000
    DetectarPopup()
    ;DetectarPopup_Img()


    contadorComentariosHechos++
    totalComentarios++
    TrayTip, AutoHotkey, Comentario enviado (#%contadorComentariosHechos%): %mensaje%, 3

    probabilidad := CalcularProbabilidad(contadorComentariosHechos, totalComentarios)
    GuardarChances(contadorComentariosHechos, probabilidad)

    ; /////////////////////// Nuevo timer random ///////////////////////
    Random, intervaloMinutos, 4, 5 
    Random, intervaloSegundos, 0, 59
    intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000
    tiempoRestante := intervalo // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    SetTimer, ActualizarTimerVisual, 1000
    SetTimer, Comentar, %intervalo%
} else {
    MsgBox, No se seleccionaron cuentas
}
Return

ActualizarTimerVisual:
if (timerActivo) {
    tiempoRestante--
    if (tiempoRestante < 0) {
        tiempoRestante := 0
        timerActivo := false
        GuiControl, TimerGUI:, TiempoRestanteText, Enviando...
    } else {
        GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    }
}
Return

; ///////////////////////////////////////// Funciones auxiliares /////////////////////////////////////////
CalcularProbabilidad(comentariosHechos, totalComentarios) {
    probabilidad := (comentariosHechos / totalComentarios) * 100
    return probabilidad
}

GuardarChances(comentariosHechos, probabilidad) {
    filePath := A_ScriptDir . "\chances.txt"
    FileAppend, comentarios_totales=%totalComentarios%`n, %filePath%
    FileAppend, comentarios_hechos=%comentariosHechos%`n, %filePath%
    FileAppend, chances=%probabilidad%`%`n, %filePath%
}

SeleccionarCuentas(filePath) {
    If !FileExist(filePath) {
        MsgBox, No existe el archivo: %filePath%
        return ""
    }
    FileRead, contenido, %filePath%
    lineas := []
    Loop, Parse, contenido, `n, `r
    {
        If (A_LoopField != "")
            lineas.push(A_LoopField)
    }
    If (lineas.MaxIndex() < 1) {
        MsgBox, El archivo está vacío
        return ""
    }
    cuentas := ""
    Loop, %cantMenciones% {
        Random, randomIndex, 1, % lineas.MaxIndex()
        cuentas .= Trim(lineas[randomIndex]) . " "
    }
    return Trim(cuentas)
}

SeleccionarEmoji() {
    emojis := ["😊", "🔥", "🎉", "✨", "😎", "🙌", "👍", "🥳", 😇]
    Random, index, 1, % emojis.MaxIndex()
    return emojis[index]
}

SeleccionarFrase() {
    frases := ["veremos","suerte","exitos","ganare?","quiero ganar","a ver si gano un sorteo","a ver que sale","suertee","xd","ojala","bueno","ojala ganarlo","messirve","buenisimoo","esperemos","esperemos que si", "espero ganar", "ojala ganar"]
    Random, index, 1, % frases.MaxIndex()
    return frases[index]
}

RandomDecision(probabilidad) {
    Random, decision, 1, 100
    return decision <= probabilidad
}

DetectarPopup() {
    ; Área donde aparece el popup de bloqueado
    X1 := 720
    Y1 := 580
    X2 := 950
    Y2 := 625

    ; Buscar el color dentro del área definida (0x0095F6 es el color RGB 0, 149, 246)
    PixelSearch, foundX, foundY, X1, Y1, X2, Y2, 0x22333F, 10, Fast RGB
    if (ErrorLevel = 0) {
        TrayTip, Popup Detectado, Cerrando pestaña (Ctrl+W), 2
        Send, ^{Tab}
        return true
    }
    return false
}
