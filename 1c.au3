;текущая дата в нужном формате
$CRDATE = @MDAY & "." & @MON & "." & @YEAR & ' ' & @HOUR & ":" & @MIN

;определяем расположение рабочих файлов и создаем лог
$name = StringRegExpReplace(@ScriptFullPath, '^.*\\|\.[^\.]*$', '')
$cfg_ini = @ScriptDir & "\" & $name & ".ini"
$cfg_log = @ScriptDir & "\" & $name & ".log"
$log_fle = FileOpen( $cfg_log, 1)
FileWrite($log_fle, @CRLF & $CRDATE & ': Начало выполнения операции' & @CRLF)

;копируем архиватор и ключ в системную папку
If Not FileExists(@SystemDir & "\winrar.exe") Then 
    If FileInstall(".\rar\winrar.exe", @SystemDir & "\winrar.exe") Then 
        FileWrite($log_fle, $CRDATE & ': Архиватор успешно установлен' & @CRLF)
    Else 
        FileWrite($log_fle, $CRDATE & ': Архиватор не установлен, возможно не прав на системную директорию!' & @CRLF)
    EndIf
Else
    FileWrite($log_fle, $CRDATE & ': Архиватор готов к работе' & @CRLF)
EndIf
If Not FileExists(@SystemDir & "\rarreg.key") Then 
	If FileInstall(".\rar\rarreg.key", @SystemDir & "\rarreg.key") Then
		FileWrite($log_fle, $CRDATE & ': Ключ защиты установлен' & @CRLF)
	Else 
		FileWrite($log_fle, $CRDATE & ': Ключ защиты не установлен, возможно не прав на системную директорию!' & @CRLF)
	EndIf
Else
    FileWrite($log_fle, $CRDATE & ': Ключ защиты обнаружен' & @CRLF)
EndIf

;читаем конфиг (в пути архиватора не должно быть пробелов и спец. символов!!!)
$str_pref = IniRead($cfg_ini, "GENERAL", "pref",  "buh")
$str_exe  = IniRead($cfg_ini, "GENERAL", "exe",   "winrar.exe")
$str_out  = IniRead($cfg_ini, "GENERAL", "out",   "c:\arhiv\buh\")
$fs_out   = IniRead($cfg_ini, "GENERAL", "fs",    "\\fs0\_Arhiv\_buh\")
$str_in   = IniRead($cfg_ini, "GENERAL", "in",    "c:\Program Files\1cv77\base\")
$spc_mb   = IniRead($cfg_ini, "GENERAL", "space", "300")

;обрезаем лишний слеш с права в пути каталога
If StringRight($str_out, 1) = '\' Then
    $str_out_trim = StringTrimRight( $str_out, 1 )
EndIf

;если мало места почистим архив
$disk_name = StringSplit($str_out, "\")
$disk_space = DriveSpaceFree($disk_name[1] & '\')
If $disk_space < $spc_mb Then
    FileWrite($log_fle, $CRDATE & ': Недостаточно свободного места. Выполняется очистка диска...' & @CRLF)
    For $i = 9 To 0 Step -1
        RunWait(@ComSpec & " /c " & "forfiles /p """ & $str_out_trim & """ /S /D -" & $i & " /C ""cmd /c del /f /a /q @file""", '', @SW_HIDE)
		If @error Then
		    FileWrite($log_fle, $CRDATE & ': Возникла ошибка в процессе выполнения комманды очистки диска!' & @CRLF)
		Else
			If DriveSpaceFree($disk_name[1] & '\') > $spc_mb  Then 
			    FileWrite($log_fle, $CRDATE & ': Процесс очистки диска успешно завершен' & @CRLF)
				ExitLoop
		    Else
			    FileWrite($log_fle, $CRDATE & ': Удалены архивы старше ' & $i & 'дней' & @CRLF)
			EndIf
		EndIf
	Next
Else
    FileWrite($log_fle, $CRDATE & ': Очистка диска не требуется' & @CRLF)
EndIf

;архивация...
FileWrite($log_fle, $CRDATE & ': Начало архивации' & @CRLF)
RunWait(@ComSpec & " /c " & $str_exe & " a -ag_yy.mm.dd_hh-mm -cfg- -dh -m3 -r0 -rr3%% " & $str_out & $str_pref & ".rar " & """" & $str_in & "*""", '', @SW_HIDE)
If @error Then
   FileWrite($log_fle, $CRDATE & ': Ошибка выполнения архивации!' & @CRLF)
Else
   FileWrite($log_fle, $CRDATE & ': Выполнение архивации прошло успешно' & @CRLF)
EndIf

;копируем архив на сервер
RunWait(@ComSpec & " /c xcopy /y /d /s """ & $str_out & "*.rar"" """ & $fs_out & """", '', @SW_HIDE)
If @error Then
   FileWrite($log_fle, $CRDATE & ': Ошибка перемещения архивов на сервер!' & @CRLF)
Else
   FileWrite($log_fle, $CRDATE & ': Перемещение архивов на сервер завершено' & @CRLF)
EndIf

;закрываем лог
FileWrite($log_fle, $CRDATE & ': Завершение программы...' & @CRLF)
FileClose($log_fle)