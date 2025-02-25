# 指定したパスの処理
function procPath($path) {
	if ($path.PSIsContainer) {
		# フォルダ
		$maxLastWriteTime = ""

		$files = Get-ChildItem $path.FullName
		foreach ($file in $files) {
			$lastWriteTime = procPath($file)
			if ($maxLastWriteTime -lt $lastWriteTime) {
				$maxLastWriteTime = $lastWriteTime
			}
		}

		# フォルダは格納されているファイルの更新日付の最大値とするが、
		# ファイルがない場合はフォルダの更新日付にする
		if ($maxLastWriteTime -eq "") {
			$maxLastWriteTime = $path.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
		}

		return change $path $maxLastWriteTime

	} else {
		# ファイル
		return change $path $path.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
	}
}

# 更新日付の分以下の4を3か5に変更
function change($path, $time) {
	$t1 = $time.SubString(0, 14)
	$t2 = $time.SubString(14)
	$t2 = [regex]::replace($t2, "4", {
		if ((Get-Random 2) -eq 0) {
			3
		} else {
			5
		}
	})
	$time = $t1 + $t2

	if ($time -ne $path.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")) {
		Set-ItemProperty $path.FullName LastWriteTime $time
	}
	return $time
}

foreach ($arg in $args) {
	if (!(Test-Path $arg)) {
		continue
	}

	$path = Get-Item $arg
	[void](procPath $path)

	# 参考用に出力
	if ($path.PSIsContainer) {
		Get-ChildItem $path.FullName | Sort-Object FullName | Select-Object FullName, {$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")} -first 10
	} else {
		$path | Select-Object FullName, {$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")}
	}
}
