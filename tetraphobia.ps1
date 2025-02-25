# �w�肵���p�X�̏���
function procPath($path) {
	if ($path.PSIsContainer) {
		# �t�H���_
		$maxLastWriteTime = ""

		$files = Get-ChildItem $path.FullName
		foreach ($file in $files) {
			$lastWriteTime = procPath($file)
			if ($maxLastWriteTime -lt $lastWriteTime) {
				$maxLastWriteTime = $lastWriteTime
			}
		}

		# �t�H���_�͊i�[����Ă���t�@�C���̍X�V���t�̍ő�l�Ƃ��邪�A
		# �t�@�C�����Ȃ��ꍇ�̓t�H���_�̍X�V���t�ɂ���
		if ($maxLastWriteTime -eq "") {
			$maxLastWriteTime = $path.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
		}

		return change $path $maxLastWriteTime

	} else {
		# �t�@�C��
		return change $path $path.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")
	}
}

# �X�V���t�̕��ȉ���4��3��5�ɕύX
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

	# �Q�l�p�ɏo��
	if ($path.PSIsContainer) {
		Get-ChildItem $path.FullName | Sort-Object FullName | Select-Object FullName, {$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")} -first 10
	} else {
		$path | Select-Object FullName, {$_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss.fffffff")}
	}
}
