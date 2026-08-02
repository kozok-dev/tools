$OUT_DIR = "out"
$GATE_THRESHOLD = -50
$LOUDNESS_THRESHOLD = -20
$MAX_SILENCE_START = 0.1
$MAX_SILENCE_END = 0.5
$LUFS = -15
$PEAK = -1
$LRA = 15

cd (Split-Path $MyInvocation.MyCommand.Path -Parent)

$filterAgate = "agate=threshold=${GATE_THRESHOLD}dB:attack=1:release=10:range=0"
$filterLoudnorm = "loudnorm=I=${LUFS}:TP=${PEAK}:LRA=${LRA}"
$filterAlimiter = "alimiter=limit=${PEAK}dB:level=0"
$filterSilencedetect = "silencedetect=noise=${GATE_THRESHOLD}dB:d=0.01"

if ((Get-Item $args[0]).PSIsContainer) {
	$outDirPath = Join-Path $args[0] $OUT_DIR
	$files = Get-ChildItem $args[0] -Filter "*.wav"
} else {
	$outDirPath = Join-Path (Split-Path $args[0] -Parent) $OUT_DIR
	$files = @(Get-Item $args[0])
}
New-Item $outDirPath -ItemType Directory 2>&1 > $null

foreach ($file in $files) {
	$inPath = $file.FullName
	$outPath = Join-Path $outDirPath $file.Name

	Write-Host $file.Name -NoNewline

	$log = .\ffmpeg -i "$inPath" -af "${filterAgate},${filterSilencedetect},ebur128=metadata=1,${filterLoudnorm}:print_format=json" -f null - 2>&1
	$logRev = .\ffmpeg -i "$inPath" -af "areverse,${filterSilencedetect}" -f null - 2>&1

	$durationLog = .\ffprobe "$inPath" -show_entries format=duration 2>&1
	$durationLog = $durationLog | Select-String "duration=([\d\.]+)"
	$duration = [double]$durationLog[0].Matches.Groups[1].Value

	$ssParam = 0
	$silenceStartDuration = 0
	$silenceLog = $log | Select-String "silencedetect"
	if ($silenceLog -and $silenceLog[0] -match "silence_start: 0$") {
		$silenceStartDuration = $silenceLog[1] | Select-String "silence_end: ([\d\.]+)"
		$silenceStartDuration = [double]$silenceStartDuration[0].Matches.Groups[1].Value

		if ($silenceStartDuration -gt $MAX_SILENCE_START) {
			$ssParam = $silenceStartDuration - $MAX_SILENCE_START
		}
	}

	$toParam = $duration
	$silenceEndDuration = 0
	$silenceLog = $logRev | Select-String "silencedetect"
	if ($silenceLog -and $silenceLog[0] -match "silence_start: 0$") {
		$silenceEndDuration = $silenceLog[1] | Select-String "silence_end: ([\d\.]+)"
		$silenceEndDuration = [double]$silenceEndDuration[0].Matches.Groups[1].Value

		if ($silenceEndDuration -gt $MAX_SILENCE_END) {
			$toParam -= $silenceEndDuration - $MAX_SILENCE_END
		}
	}

	$loudnessLog = $log | Select-String "I:\s+([\-\d\.]+)\s+LUFS"
	if (!$loudnessLog) {
		Write-Host " error"
		continue
	}
	$orgLoudness = [double]$loudnessLog[0].Matches.Groups[1].Value

	Write-Host (" D=${duration}s SS=${silenceStartDuration}s SE=${silenceEndDuration}s ${orgLoudness}LUFS") -NoNewline

	$filter = $filterAgate

	if ($orgLoudness -ge $LUFS) {
		$filter += ",$filterAlimiter"
		Write-Host " limiter"

	} elseif ($orgLoudness -ge $LOUDNESS_THRESHOLD) {
		$inputI = $log | Select-String "`"input_i`"\s*:\s*`"([\d\.\-]+)`""
		$inputI = [double]$inputI[0].Matches.Groups[1].Value
		$inputTp = $log | Select-String "`"input_tp`"\s*:\s*`"([\d\.\-]+)`""
		$inputTp = [double]$inputTp[0].Matches.Groups[1].Value
		$inputLra = $log | Select-String "`"input_lra`"\s*:\s*`"([\d\.\-]+)`""
		$inputLra = [double]$inputLra[0].Matches.Groups[1].Value
		$inputThresh = $log | Select-String "`"input_thresh`"\s*:\s*`"([\d\.\-]+)`""
		$inputThresh = [double]$inputThresh[0].Matches.Groups[1].Value

		$filter += ",${filterLoudnorm}:linear=true:measured_I=${inputI}:measured_TP=${inputTp}:measured_LRA=${inputLra}:measured_thresh=${inputThresh}"

		Write-Host " loudnorm"

	} else {
		Write-Host " none"
	}

	.\ffmpeg -y -ss $ssParam -to $toParam -i "$inPath" -af "$filter,aresample=44100" "$outPath" 2>&1 > $null
}
