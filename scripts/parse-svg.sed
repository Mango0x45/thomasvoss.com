/^<svg/,/^<\/svg>$/ {
	/^<svg/s/pt"/"/g
	s/ *xmlns:xlink="[^"]*"//
	/<!--.*-->/!p
}
