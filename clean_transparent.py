#!/usr/bin/env python
# -*- coding: utf-8 -*-

from gimpfu import *
import os, re

def plugin_main(is_bulk, dir_path):
	pdb.gimp_context_push()

	pdb.gimp_context_set_default_colors()
	pdb.gimp_context_set_opacity(100)
	pdb.gimp_context_set_paint_mode(LAYER_MODE_NORMAL)

	# アンチエイリアスなし、境界ぼかしなしで透明部分を選択できるようにする
	pdb.gimp_context_set_antialias(False)
	pdb.gimp_context_set_feather(False)
	pdb.gimp_context_set_feather_radius(0, 0)
	pdb.gimp_context_set_sample_threshold(0)
	pdb.gimp_context_set_sample_transparent(True)

	if is_bulk:
		# 指定したディレクトリにあるpng,xcfを処理
		for file in pdb.file_glob(dir_path + os.sep + "*", 0)[1]:
			if not(os.path.isfile(file.encode("cp932")) and re.search("\.(png|xcf)$", file, re.I)):
				continue

			# 画像を開く
			image = pdb.gimp_file_load(file, os.path.basename(file))
			pdb.gimp_image_undo_disable(image)

			display = pdb.gimp_display_new(image)

			if proc_image(image):
				# 画像を上書き保存
				drawable = pdb.gimp_image_get_active_drawable(image)
				pdb.gimp_file_save(image, drawable, image.filename, image.name)

			pdb.gimp_display_delete(display)
	else:
		# 開いている画像を処理
		for image in gimp.image_list():
			pdb.gimp_image_undo_group_start(image)
			proc_image(image)
			pdb.gimp_image_undo_group_end(image)

	pdb.gimp_context_pop()

def proc_image(image):
	drawable = pdb.gimp_image_get_active_drawable(image)

	# インデックスカラー画像は何もしない
	if pdb.gimp_drawable_is_indexed(drawable):
		return

	# グレースケール画像はRGBチャンネルに作用させるため、RGBに変換
	gray = pdb.gimp_drawable_is_gray(drawable)
	if gray:
		pdb.gimp_image_convert_rgb(image)

	# 見えている色で処理を行うため、RGBAチャンネルを表示
	for channel in (CHANNEL_RED, CHANNEL_GREEN, CHANNEL_BLUE, CHANNEL_ALPHA):
		pdb.gimp_image_set_component_visible(image, channel, True)

	# 変更必要可否のチェック用画像としてコピーを作成
	check_image = pdb.gimp_image_duplicate(image)
	pdb.gimp_image_undo_disable(check_image)

	# 比較用の元画像としてコピーを作成
	org_image = pdb.gimp_image_duplicate(image)
	pdb.gimp_image_undo_disable(org_image)

	# 黒以外の透明ピクセルがあれば変更の必要ありとなるが、その準備として
	# アルファ値を無視してレイヤー毎に色選択できるようにアルファチャンネルを非表示にして
	# 各レイヤーを非表示の標準モードで不透明度100にし、対象のレイヤーのみ表示して処理できるようにする
	pdb.gimp_image_set_component_visible(check_image, CHANNEL_ALPHA, False)
	init_check_layer(check_image, check_image.layers)

	changes = check_layer(check_image, check_image.layers)
	pdb.gimp_image_delete(check_image)

	if True in changes:
		active_layer = pdb.gimp_image_get_active_layer(image)

		# レイヤーの透明度で選択できるようにする
		pdb.gimp_context_set_sample_merged(False)
		pdb.gimp_context_set_sample_criterion(SELECT_CRITERION_A)

		change_layer(image, image.layers, changes)

		pdb.gimp_selection_none(image)
		pdb.gimp_image_set_active_layer(image, active_layer)

		# 比較用の変換後画像としてコピーを作成
		change_image = pdb.gimp_image_duplicate(image)
		pdb.gimp_image_undo_disable(change_image)

		# グレースケール画像はRGBになっているので戻す
		if gray:
			pdb.gimp_image_convert_grayscale(image)

		cmp_image(org_image, change_image)

		pdb.gimp_image_delete(change_image)

	pdb.gimp_image_delete(org_image)
	return True in changes

# 各レイヤーを非表示の標準モードで不透明度100にする
def init_check_layer(image, layers):
	for layer in layers:
		pdb.gimp_item_set_visible(layer, False)
		pdb.gimp_layer_set_mode(layer, LAYER_MODE_NORMAL)
		pdb.gimp_layer_set_opacity(layer, 100)

		if pdb.gimp_item_is_group(layer):
			init_check_layer(image, layer.layers)

# 各レイヤーの変更必要可否一覧を取得
def check_layer(image, layers):
	changes = []
	for layer in layers:
		if pdb.gimp_item_is_group(layer):
			pdb.gimp_item_set_visible(layer, True)
			changes.extend(check_layer(image, layer.layers))
			pdb.gimp_item_set_visible(layer, False)

		elif pdb.gimp_item_is_layer(layer):
			# まず、対象レイヤーを変更なしとしてマーク
			changes.append(False)

			pdb.gimp_image_set_active_layer(image, layer)
			drawable = pdb.gimp_image_get_active_drawable(image)

			# アルファ値を持たないレイヤーは変更の必要なし
			if not pdb.gimp_drawable_has_alpha(drawable):
				continue

			pdb.gimp_item_set_visible(layer, True)

			# 見えている色で選択できるようにする
			pdb.gimp_context_set_sample_merged(True)
			pdb.gimp_context_set_sample_criterion(SELECT_CRITERION_COMPOSITE)

			# 黒ピクセル以外を選択
			pdb.gimp_image_select_color(image, CHANNEL_OP_REPLACE, drawable, (0, 0, 0, 1))
			pdb.gimp_selection_invert(image)

			# レイヤーの透明度で選択できるようにする
			pdb.gimp_context_set_sample_merged(False)
			pdb.gimp_context_set_sample_criterion(SELECT_CRITERION_A)

			# 透明ピクセルでAND選択
			pdb.gimp_image_select_color(image, CHANNEL_OP_INTERSECT, drawable, (0, 0, 0, 0))

			pdb.gimp_item_set_visible(layer, False)

			# 選択が空の場合、黒以外の透明ピクセルがないので変更の必要なし
			if pdb.gimp_selection_is_empty(image):
				continue

			# 対象レイヤーを変更ありとしてマーク
			changes[-1] = True
	return changes

# 各レイヤー変更
def change_layer(image, layers, changes, index = -1):
	for layer in layers:
		if pdb.gimp_item_is_group(layer):
			# ピクセル保護を無効化
			lock_content = pdb.gimp_item_get_lock_content(layer)
			pdb.gimp_item_set_lock_content(layer, False)

			expanded = pdb.gimp_item_get_expanded(layer)

			index = change_layer(image, layer.layers, changes, index)

			# ピクセル保護、レイヤーグループの展開状態を戻す
			pdb.gimp_item_set_lock_content(layer, lock_content)
			pdb.gimp_item_set_expanded(layer, expanded)

		elif pdb.gimp_item_is_layer(layer):
			index += 1
			# 変更の必要なしなら何もしない
			if not changes[index]:
				continue

			pdb.gimp_image_set_active_layer(image, layer)
			drawable = pdb.gimp_image_get_active_drawable(image)

			# 透明ピクセルを選択
			pdb.gimp_image_select_color(image, CHANNEL_OP_REPLACE, drawable, (0, 0, 0, 0))

			# 念のため、選択が空なら何もしない
			if pdb.gimp_selection_is_empty(image):
				continue

			# ピクセル保護、透明保護を無効化
			lock_content = pdb.gimp_item_get_lock_content(layer)
			lock_alpha = pdb.gimp_layer_get_lock_alpha(layer)
			pdb.gimp_item_set_lock_content(layer, False)
			pdb.gimp_layer_set_lock_alpha(layer, False)

			# 透明ピクセルを全て黒にした直後クリア
			pdb.gimp_drawable_edit_fill(drawable, FILL_FOREGROUND)
			pdb.gimp_drawable_edit_clear(drawable)

			# ピクセル保護、透明保護を戻す
			pdb.gimp_item_set_lock_content(layer, lock_content)
			pdb.gimp_layer_set_lock_alpha(layer, lock_alpha)
	return index

# 差異はないはずだが、念のため簡易的に比較
def cmp_image(org_image, change_image):
	# 元画像を統合
	org_layer = pdb.gimp_image_flatten(org_image)
	pdb.gimp_image_set_active_layer(org_image, org_layer)

	# 変更後画像を統合
	pdb.gimp_image_flatten(change_image)

	# 変更後画像を元画像の一番上のレイヤーとしてコピーし、色消しゴムモードにする
	change_drawable = pdb.gimp_image_get_active_drawable(change_image)
	change_layer = pdb.gimp_layer_new_from_drawable(change_drawable, org_image)
	pdb.gimp_image_insert_layer(org_image, change_layer, None, 0)
	pdb.gimp_layer_set_mode(change_layer, LAYER_MODE_COLOR_ERASE)

	# 見えている色で選択できるようにする
	pdb.gimp_context_set_sample_merged(True)
	pdb.gimp_context_set_sample_criterion(SELECT_CRITERION_COMPOSITE)

	# 透明ピクセル以外を選択
	pdb.gimp_image_set_active_layer(org_image, change_layer)
	org_drawable = pdb.gimp_image_get_active_drawable(org_image)
	pdb.gimp_image_select_color(org_image, CHANNEL_OP_REPLACE, org_drawable, (0, 0, 0, 0))
	pdb.gimp_selection_invert(org_image)

	# 選択が空でなければ差異ありのため、処理中止
	if not pdb.gimp_selection_is_empty(org_image):
		pdb.gimp_display_new(org_image)
		raise Exception("元画像と差異があります")

register(
	"clean_transparent",
	"色が残っている透明ピクセルを黒の透明に変換します\n※ディレクトリ指定の場合はPNG,XCFが対象となり、画像ファイルが変更されるので予めバックアップを推奨します",
	"",
	"kozok",
	"kozok",
	"2025-02-22",
	"Clean Transparent",
	"",
	[
		(PF_BOOL, "is_bulk", "ディレクトリ指定", False),
		(PF_DIRNAME, "dir_path", "変換対象ディレクトリ", "")
	],
	[],
	plugin_main,
	menu = "<Image>/File/Export")

main()
