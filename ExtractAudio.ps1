$Video = Read-Host("location of input video")
$format = $Video.Trim('"',' ')
$Obj = (Get-Item -LiteralPath "$format")
$Output = $Obj.BaseName
Write-Host "Video: $Output"
$Path = $Obj.DirectoryName + "\"
$Path
$x = 0
$log = @()

$JSON = (ffprobe "$Video" -hide_banner -select_streams a -show_entries stream=codec_name -loglevel -8 -print_format json)
$log += "---Raw ffprobe data---`n$JSON`n------------------------------------------------------------"
$JSON = $JSON | ConvertFrom-Json
$log += "`n`n---Converted JSON---`n$JSON`n------------------------------------------------------------"
ForEach ($Codec in $JSON.streams){
    $log += "`n`nFound: $Codec`nCodec: $Codec.codec_name"
    $extension = $Codec.codec_name

    if ($extension -eq $null){
        $log += "`n`nERROR`n------COULDNT FIND CODEC_NAME.`nValue: $Codec"
        return
    }
    else{
        if ($extension -eq "pcm_s16le"){
            $log += "Found pcm_s16le codec. Using .wav extension as default."
            $extension = "wav"
        }
        $end = ("_" + [string]($x + 1) + ".$extension")
        $log += "Creating end of filename format: $end"
        & ffmpeg -i "$Video" -report -loglevel -8 -hide_banner -map 0:a:$x -c copy "$Path$Output$end"
        $x = $x + 1
    }
}
Write-Host "Audio tracks extracted: $x"
$log += "`n`nDone!"
$log | out-file $Path"ExtractAudio.log"

Write-Host "Press any key to continue ..."
$C = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
clear