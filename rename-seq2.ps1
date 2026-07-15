$PREFIX = "file"
$SUFFIX = ""

$targetDir = [System.IO.Path]::GetDirectoryName($args[0])
$renames = Import-Csv (Join-Path $targetDir "_rename-seq.csv")
$content = [IO.File]::ReadAllText($args[0])

foreach ($rename in $renames) {
	$pattern = $PREFIX + [Regex]::Escape($rename.old) + $SUFFIX
	$replacement = "<<" + $PREFIX + $rename.old + $SUFFIX + ">>"

	$content = $content -replace $pattern, $replacement
}

foreach ($rename in $renames) {
	$pattern = "<<" + $PREFIX + [Regex]::Escape($rename.old) + $SUFFIX + ">>"
	$replacement = $PREFIX + $rename.new + $SUFFIX

	$content = $content -replace $pattern, $replacement
}

[IO.File]::WriteAllText($args[0] + ".new", $content, (New-Object Text.UTF8Encoding($false)))
