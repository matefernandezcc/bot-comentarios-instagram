#Persistent
CoordMode, Mouse, Screen
EnvGet, userProfile, USERPROFILE
SetWorkingDir, %A_ScriptDir%

; ///////////////////////////////////////// Variables de config globales /////////////////////////////////////////
global limiteDiario := 500 ; Cantidad máxima de comentarios a enviar
global url := "https://www.instagram.com/p/DNhDv60tjd2/?img_index=1" ; URL / nombre del sorteo actual

global totalComentarios := 2038 ; Cantidad de comentarios totales que tiene la publicación
global contadorComentariosHechos := 441 ; Comentarios YA hechos
global cantidadCuentas := 4 ; Cantidad de cuentas a rotar
global comentariosPorCuenta := 5 ; Comentarios a enviar por cada cuenta antes de cambiar
global cantMenciones := 3 ; Cantidad de cuentas a mencionar por comentario

global inputX := 1181, inputY := 716 ; Coords del input text

global penalizacion := 0 ; Tiempo sumado por cada vez que te bloquean acciones (en minutos)
global primerTimer := 5000 ; Delay inicial antes de comenzar (ms)
global intervaloMinutos, intervaloSegundos, intervalo
global timerActivo := false
global tiempoRestante := 0

; ///////////////////////////////////////// Crear GUI una vez /////////////////////////////////////////
Gui, TimerGUI:+AlwaysOnTop -Caption +ToolWindow
Gui, TimerGUI:Font, s14 Bold, Segoe UI
Gui, TimerGUI:Add, Text, vTiempoRestanteText w200 Center, Esperando...
Gui, TimerGUI:Add, Text, vPenalizacionText w200 Center, Penalización: 0m
Gui, TimerGUI:Show, x40 y75 NoActivate, Timer Visual

; ///////////////////////////////////////// Inicio del ciclo /////////////////////////////////////////
Comenzar:
    tiempoRestante := primerTimer // 1000
    timerActivo := true
    GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
    GuiControl, TimerGUI:, PenalizacionText, Penalización: %penalizacion%m
    SetTimer, ActualizarTimerVisual, 1000
    SetTimer, IniciarCicloPrimero, %primerTimer%
Return

IniciarCicloPrimero:
    SetTimer, IniciarCicloPrimero, Off
    timerActivo := false
    GuiControl, TimerGUI:, TiempoRestanteText, Enviando...
    Gosub, CicloCuentas
Return

CicloCuentas:
if (contadorComentariosHechos >= limiteDiario) {
    TrayTip, AutoHotkey, Límite diario alcanzado (%limiteDiario% comentarios), 5
    SetTimer, ActualizarTimerVisual, Off
    GuiControl, TimerGUI:, TiempoRestanteText, Límite alcanzado!
    Return
}

; Mostrar estado de envío
timerActivo := false
GuiControl, TimerGUI:, TiempoRestanteText, Enviando...

; Asegurar Opera activa
WinActivate, ahk_exe opera.exe
WinWaitActive, ahk_exe opera.exe,, 3
If !WinActive("ahk_exe opera.exe") {
    MsgBox, No pude activar la ventana de Opera
    Return
}

; Procesar cada cuenta
Loop, %cantidadCuentas% {
    if (contadorComentariosHechos >= limiteDiario) {
        break
    }

    ; Foco en el cuadro de comentarios una sola vez por cuenta
    Sleep 400
    MouseMove, %inputX%, %inputY% ; Coords del input text
    Sleep 200
    Click left
    Sleep 300
    ; Limpiar cualquier texto previo en el input
    Send, ^a
    Sleep 80
    Send, {Delete}
    Sleep 120

    ; Enviar N comentarios seguidos con Enter
    Loop, %comentariosPorCuenta% {
        if (contadorComentariosHechos >= limiteDiario) {
            break
        }
        enviado := EnviarUnComentario()
        if (!enviado) {
            ; Si falló la construcción del mensaje (p. ej., sin cuentas), abortar ciclo
            MsgBox, No se pudo construir el comentario. Abortando ciclo.
            Return
        }
        Sleep 1200
    }

    ; Cambiar de cuenta después de cada cuenta (la última vuelve a la inicial)
    CambiarCuenta()
    Sleep 1200
}

; Programar espera larga antes de repetir todo el ciclo
Gosub, ProgramarEsperaLarga
Return

ProgramarEsperaLarga:
Random, intervaloMinutos, 10, 15
Random, intervaloSegundos, 0, 59
intervalo := intervaloMinutos * 60000 + intervaloSegundos * 1000 + penalizacion * 60000
tiempoRestante := intervalo // 1000
timerActivo := true
GuiControl, TimerGUI:, TiempoRestanteText, Restante: %tiempoRestante%s
GuiControl, TimerGUI:, PenalizacionText, Penalización: %penalizacion%m
SetTimer, ActualizarTimerVisual, 1000
SetTimer, RepetirCiclo, %intervalo%
Return

RepetirCiclo:
SetTimer, RepetirCiclo, Off
Gosub, CicloCuentas
Return

EnviarUnComentario() {
    global contadorComentariosHechos, totalComentarios
    cuentas := SeleccionarCuentas(A_ScriptDir . "\\cuentas.txt")
    if (cuentas = "")
        return false

    emoji := SeleccionarEmoji()
    frase := SeleccionarFrase()
    if (RandomDecision(50))
        emoji := ""
    if (RandomDecision(50))
        frase := ""

    mensaje := Trim(cuentas " " frase " " emoji)

    ; Se asume que el input ya está focuseado. Limpiar antes de pegar
    Send, ^a
    Sleep 80
    Send, {Delete}
    Sleep 120
    SendInput %mensaje%
    Sleep 1200
    SendInput {Enter}
    Sleep 800

    contadorComentariosHechos++
    totalComentarios++
    TrayTip, AutoHotkey, Comentario enviado (#%contadorComentariosHechos%): %mensaje%, 2

    probabilidad := CalcularProbabilidad(contadorComentariosHechos, totalComentarios)
    GuardarChances(contadorComentariosHechos, probabilidad)

    return true
}

CambiarCuenta() {
    ; Enviar combinación Ctrl+Tab para cambiar de pestaña/cuenta
    Send, ^{Tab}
    Sleep 150
}

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
    FormatTime, fechaHora, %A_Now%, dd-MM HH:mm

    FileAppend, Fecha=%fechaHora%`n, %filePath%
    FileAppend, Sorteo=%url%`n, %filePath% ;
    FileAppend, Comentarios hechos=%comentariosHechos%`n, %filePath%
    FileAppend, Comentarios totales=%totalComentarios%`n, %filePath%
    FileAppend, probabilidad=%probabilidad%`%`n, %filePath%
    FileAppend, `n, %filePath%
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
    emojis := ["😊", "🔥", "🎉", "✨", "😎", "🙌", "👍", "🥳", "😇", "😍", "🤩", "🎯", "💥", "😜", "🤗", "💪", "🤞", "🌟", "🌈", "💖", "💫", "😝", "🌻", "💬", "🙈", "💥", "🍀"]
    Random, index, 1, % emojis.MaxIndex()
    return emojis[index]
}

SeleccionarFrase() {
    frases := ["veremos", "suerte", "exitos", "ganare?", "quiero ganar", "a ver si gano un sorteo", "a ver que sale", "suertee", "xd", "ojala", "bueno", "ojala ganarlo", "messirve", "buenisimoo", "esperemos", "esperemos que si", "espero ganar", "ojala ganar", "seria genial", "deseando ganar", "este es mi momento", "crucemos los dedos", "si lo gano, ¡genial!", "todo por un sorteo", "a ganar", "me gustaría mucho", "vamos a ver", "tengo fe"]
    Random, index, 1, % frases.MaxIndex()
    return frases[index]
}

RandomDecision(probabilidad) {
    Random, decision, 1, 100
    return decision <= probabilidad
}

; Se removieron funciones de detección de popups por no ser necesarias
