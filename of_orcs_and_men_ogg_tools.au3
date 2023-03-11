#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
#include <File.au3>
#include <Array.au3>
#include <ButtonConstants.au3>
#include <String.au3>
#Include <EditConstants.au3>

Global $iDrive, $iDir, $iName, $iExp

Opt("GUIOnEventMode", 1)
$hGui = GUICreate("OGG Tools", 250, 170, -1, -1)

GUICtrlCreateTab(1, 1, 249, 168)
GUICtrlCreateTabItem("Unpacker")
GUICtrlSetState(-1, $GUI_SHOW)

$iEdit1 = GUICtrlCreateEdit('', 5, 25, 240, 100, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_NOHIDESEL + $ES_WANTRETURN)
GUICtrlSendMsg(-1, $EM_LIMITTEXT, -1, 0)

$idButton1 = GUICtrlCreateButton("Open File", 125, 130, 120, 30)
GUICtrlSetOnEvent($idButton1, "Game_FileOpen")

$idButton2 = GUICtrlCreateButton("Open Folder", 5, 130, 120, 30)
GUICtrlSetOnEvent($idButton2, "Game_FolderOpen")

GUICtrlCreateTab(1, 1, 249, 168)
GUICtrlCreateTabItem("Packer")

$iEdit2 = GUICtrlCreateEdit('', 5, 25, 240, 100, $ES_AUTOVSCROLL + $WS_VSCROLL + $ES_NOHIDESEL + $ES_WANTRETURN)
GUICtrlSendMsg(-1, $EM_LIMITTEXT, -1, 0)

$idButton3 = GUICtrlCreateButton("Open File", 125, 130, 120, 30)
GUICtrlSetOnEvent($idButton3, "OGG_FileOpen")

$idButton4 = GUICtrlCreateButton("Open Folder", 5, 130, 120, 30)
GUICtrlSetOnEvent($idButton4, "OGG_FolderOpen")

$iLogFile = FileOpen (@ScriptDir & '\ogg_tools.log', 9)
DirCreate (@TempDir & '\ogg_tools\')

Func OGG_FileOpen()
	Global $iFilePath = FileOpenDialog ('', '', '(*.ogg)', 1)
	
		If @error <> 1 Then
			OGG_Packer()
		EndIf
		
EndFunc

Func OGG_FolderOpen()
	$iFolderList = FileSelectFolder("", "")
	
	If @error <> 1 Then
		GUICtrlSetData($iEdit2, "Wait!" & @CRLF & "File list is creation..." & @CRLF, 1)
		FileWriteLine ($iLogFile, "Wait!" & @CRLF & "File list is creation..." & @CRLF)
		$iFile = FileOpen(@TempDir & "\ogg_tools\temp.bat", 10)
		FileWriteLine ($iFile, "chcp 65001")
		FileWriteLine ($iFile, "@echo off")
		FileWriteLine ($iFile, "DIR/B/O:N/S """ & $iFolderList & """ > " & @TempDir & "\ogg_tools\file_list.txt");
		FileClose ($iFile)
		ShellExecuteWait (@TempDir & "\ogg_tools\temp.bat", "", @ScriptDir, "open")
		;Создать скрипт для пакетной обработки
		Local $iStringCount = _FileCountLines(@TempDir & "\ogg_tools\file_list.txt")
		$a = 0
		
			While $a <= $iStringCount
				$a = $a + 1
				Global $iFilePath = FileReadLine (@TempDir & "\ogg_tools\file_list.txt", $a)
				OGG_Packer()
			WEnd
			
	EndIf
	
EndFunc

Func Game_FileOpen()
	Global $iFilePath = FileOpenDialog ('', '', '(*)', 1)
	
	If @error <> 1 Then
		OGG_Unpacker()
	EndIf
	
EndFunc

Func Game_FolderOpen()
	$iFolderList = FileSelectFolder("", "")
	
	If @error <> 1 Then
		GUICtrlSetData($iEdit1, "Wait!" & @CRLF & "File list is creation..." & @CRLF, 1)
		FileWriteLine ($iLogFile, "Wait!" & @CRLF & "File list is creation..." & @CRLF)
		$iFile = FileOpen(@TempDir & "\ogg_tools\temp.bat", 10)
		FileWriteLine ($iFile, "chcp 65001")
		FileWriteLine ($iFile, "@echo off")
		FileWriteLine ($iFile, "DIR/B/O:N/S """ & $iFolderList & """ > " & @TempDir & "\ogg_tools\file_list.txt");
		FileClose ($iFile)
		ShellExecuteWait (@TempDir & "\ogg_tools\temp.bat", "", @ScriptDir, "open")
		;Создать скрипт для пакетной обработки
		Local $iStringCount = _FileCountLines(@TempDir & "\ogg_tools\file_list.txt")
		$a = 0
		
		While $a <= $iStringCount
			$a = $a + 1
			Global $iFilePath = FileReadLine (@TempDir & "\ogg_tools\file_list.txt", $a)
			OGG_Unpacker()
		WEnd
		
	EndIf
	
EndFunc

Func OGG_Unpacker()
	_PathSplit($iFilePath, $iDrive, $iDir, $iName, $iExp)
	$iFile = FileOpen ($iFilePath, 16)
	$iFileHead = FileRead ($iFile, 3)
	
	If $iFileHead = ('0x1F8B08') Then
		$iFile = FileClose ($iFilePath)
		gzip_unpack()
	ElseIf $iFileHead = ('0x505353') Then
		FileSetPos ($iFile, 858+StringLen ($iName), 0)
		$iOffset = FileRead ($iFile, 4)
		$iFileSize = Dec (StringTrimLeft ($iOffset, 2))
		FileSetPos ($iFile, 866+StringLen ($iName), 0)
		$iOGGSource = FileRead ($iFile, $iFileSize)
		$iOGGFile = FileOpen (@ScriptDir & '\OUT\' & $iName & '.ogg', 26)
		FileWrite ($iOGGFile, $iOGGSource)
		FileClose ($iOGGFile)
		FileSetPos ($iFile, 866+StringLen ($iName)+$iFileSize, 0)
		$iLIPSource = FileRead ($iFile)
		$iLIPFile = FileOpen (@ScriptDir & '\OUT\' & $iName & '.lip', 26)
		FileWrite ($iLIPFile, $iLIPSource)
		FileClose ($iLIPFile)
		FileClose ($iFile)
		FileWriteLine ($iLogFile, "Done!" & @CRLF & "File " & $iName & ".lip" & " is saved!" & @CRLF)
		GUICtrlSetData($iEdit1, "Done!" & @CRLF & "File " & $iName & ".lip" & " is saved!" & @CRLF, 1)
		GUICtrlSetData($iEdit1, "Done!" & @CRLF & "File " & $iName & ".ogg" & " is saved!" & @CRLF, 1)
		FileWriteLine ($iLogFile, "Done!" & @CRLF & "File " & $iName & ".ogg" & " is saved!" & @CRLF)
	Else
		GUICtrlSetData ($iEdit1, 'Error! File ' & $iName & $iExp & ' is not a audio file from the game "Of orc and human"' & @CRLF, 1)
		FileWriteLine ($iLogFile, 'Error! File ' & $iName & $iExp & ' is not a audio file from the game "Of orc and human"' & @CRLF)
	EndIf
	
EndFunc

Func gzip_unpack()

	_PathSplit($iFilePath, $iDrive, $iDir, $iName, $iExp)
	FileCopy ($iFilePath, @TempDir & '\ogg_tools\' &  $iName & '.gz')
	ShellExecuteWait (@ScriptDir & "\data\gzip.exe", ' -d ' & @TempDir & '\ogg_tools\' &  $iName & '.gz', '', "open", @SW_HIDE)
	$iFilePath = (@TempDir & '\ogg_tools\' & $iName)
	OGG_Unpacker()
	
EndFunc

Func OGG_Packer()

	_PathSplit($iFilePath, $iDrive, $iDir, $iName, $iExp)
	$iOGGFile = FileOpen ($iFilePath, 16)
	$iFileHead = FileRead ($iOGGFile, 4)
	
		If $iFileHead = ('0x4F676753') Then
			If FileExists ($iDrive & $iDir & $iName & ".lip") Then
				$iNewFile = FileOpen (@ScriptDir & '\OUT\' & $iName, 26)
				$iLIPFile = FileOpen ($iDrive & $iDir & $iName & ".lip", 16)
				$iOGGSize = FileGetSize ($iFilePath)
				$iLIPSize = FileGetSize ($iDrive & $iDir & $iName & ".lip")
				$iNameLong = StringLen ($iName)
				$AchiveSize = ($iOGGSize+$iLIPSize+858+$iNameLong)
				FileWrite ($iNewFile, "0x50535347")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($AchiveSize), 8))
				FileWrite ($iNewFile,  "0x000000110000000B0000000100000009415544494F4441544100000002000000010000000C62696E6172794F626A526566000000020000000B6D61726B6572436F756E7400000002000000074F4747444154410000000000000003000000114C495053594E435F414E494D4154494F4E0000000000000004000000114C495053594E435F44415441424C4F434B000000040000000300000005776964746800000004000000066C656E6774680000000500000009737461727454696D650000000600000007656E6454696D6500000005000000174C495053594E435F44415441424C4F434B5F56414C554500000000000000060000000C50535347444154414241534500000005000000070000000D73706964657256657273696F6E000000080000001173706964657246696C6556657273696F6E00000009000000157370696465724C61796572656444617461626173650000000A000000057363616C650000000B00000002757000000007000000074C494252415259000000010000000C0000000474797065000000080000000854595045494E464F000000020000000D00000008747970654E616D650000000E0000000974797065436F756E740000000900000003585858000000010000000F0000000269640000000A0000000C42494E4152594F424A45435400000001000000100000000E62696E6172794461746153697A650000000B0000000A42494E415259444154410000000000000006")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($AchiveSize-546), 8))
				FileWrite ($iNewFile,  "0x0000004C0000000700000004000000000000000800000004000000000000000900000004000000000000000A0000000C3F8000003F8000003F8000000000000B0000000C000000003F800000000000000000000800000028000000240000000D000000100000000C42494E4152594F424A4543540000000E0000000400000001000000080000002D000000290000000D00000015000000114C495053594E435F414E494D4154494F4E0000000E000000040000000100000008000000230000001F0000000D0000000B000000074F4747444154410000000E000000040000000100000007")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($iOGGSize+$iNameLong+76), 8))
				FileWrite ($iNewFile, "0x000000180000000C000000100000000C42494E4152594F424A4543540000000A")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($iOGGSize+$iNameLong+40), 8))
				FileWrite ($iNewFile, "0x" & Hex ($iNameLong+28))
				FileWrite ($iNewFile, "0x0000001000000004")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($iOGGSize-4), 8))
				;FileWrite ($iNewFile, "0x0000000F000000130000000F");ЗДЕСЬ Error!!!!!!
				FileWrite ($iNewFile, "0x0000000F")
				FileWrite ($iNewFile, "0x" & Hex ($iNameLong+8))
				FileWrite ($iNewFile, "0x" & Hex ($iNameLong+4))
				FileWrite ($iNewFile, $iName)
				FileWrite ($iNewFile, "0x2E6F67670000000B")
				FileWrite ($iNewFile, "0x" & StringTrimleft (Hex ($iOGGSize), 8))
				FileWrite ($iNewFile, "0x00000000")
				FileSetPos ($iOGGFile, 0, 0)
				$iOGGData = FileRead ($iOGGFile)
				FileWrite ($iNewFile, $iOGGData)
				FileSetPos ($iLIPFile, 0, 0)
				$iLIPData = FileRead ($iLIPFile)
				FileWrite ($iNewFile, $iLIPData)
				FileClose ($iNewFile)
				FileClose ($iLIPFile)
				;FileSetTime (@ScriptDir & '\OUT\' & $iName, "20120810160100")
				ShellExecuteWait (@ScriptDir & "\data\gzip.exe", ' -1 ' & @ScriptDir & '\OUT\' & $iName, '', "open", @SW_HIDE)
				FileMove (@ScriptDir & '\OUT\' & $iName & '.gz', @ScriptDir & '\OUT\' & $iName & '.pgz')
				GUICtrlSetData($iEdit2, "Done!" & @CRLF & "File " & $iName & " is saved!" & @CRLF, 1)
				FileWriteLine ($iLogFile, "Done!" & @CRLF & "File " & $iName & " is saved!" & @CRLF)
			Else
				GUICtrlSetData ($iEdit2, 'Error! Missing file ' & $iName & ".lip!" & @CRLF, 1)
				FileWriteLine ($iLogFile, 'Error! Missing file ' & $iName & ".lip!" & @CRLF)
			EndIf
		;Else
			;GUICtrlSetData ($iEdit2, 'Error! File ' & $iName & $iExp & ' не является OGG Vorbis Fileом' & @CRLF, 1)
			;FileWriteLine ($iLogFile, 'Error! File ' & $iName & $iExp & ' не является OGG Vorbis Fileом' & @CRLF)
		EndIf
		
	FileClose ($iOGGFile)
EndFunc

GUISetState()

GUISetOnEvent($GUI_EVENT_CLOSE, "AppClose")

Func AppClose()
	FileClose ($iLogFile)
	DirRemove (@TempDir & '\ogg_tools\', 1)
	Exit
EndFunc

Do
Until GUIGetMsg() = $GUI_EVENT_CLOSE

