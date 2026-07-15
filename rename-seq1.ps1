$TARGET_EXT = "^\.(jpg|png|mp3|wav)$"
$PREFIX = "file"
$SUFFIX = ""
$INDEX = 1

function natualSort {
	return $args[0] | Sort-Object {
		$parts = $_ -split "(\d+)"
		($parts | ForEach-Object {
			if ($_ -match "^\d+$") {
				"{0:D10}" -f [int]$_
			} else {
				$_.ToLower()
			}
		}) -join ''
	}
}
$files = Get-ChildItem $args[0] | Where-Object { $_.Extension -match $TARGET_EXT }
$files = natualSort($files.Name)

$items = @()
for ($i = 0; $i -lt $files.Count; $i++) {
	$old = $files[$i]
	$ext = [IO.Path]::GetExtension($old)
	$tmp = "_tmp_$i$ext"

	Rename-Item (Join-Path $args[0] $old) $tmp

	$items += [PSCustomObject]@{
		old = $old
		tmp = $tmp
	}
}

$renames = @()
foreach ($item in $items) {
	$ext = [IO.Path]::GetExtension($item.old)
	$new = "$PREFIX$index$SUFFIX$ext"

	Rename-Item (Join-Path $args[0] $item.tmp) $new

	$renames += [PSCustomObject]@{
		old = $item.old
		new = $new
	}

	$INDEX++
}

$csv = Join-Path $args[0] "_rename-seq.csv"
$renames | Export-Csv $csv -Encoding UTF8 -NoTypeInformation
