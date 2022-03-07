#! /bin/sh
# vim: set tabstop=4 syntax=sh :
# SPDX-License-Identifier: GPL-2.0-or-later
dissect_fit_image()
(
	printf_ss() {
		mask="$1"
		shift
		# shellcheck disable=SC2059
		printf -- "$mask" "$@"
	}
	msg() { [ "$debug" -eq 1 ] || return; printf_ss "$@" 1>&2; }
	out() (
		mask="$1"
		shift
		IFS=""
		# shellcheck disable=SC2059
		line="$(printf -- "$mask" "$@")"
		printf -- "%s" "$line"
		printf -- "%s" "$line" >>"$its_file"
		if [ "$(expr "$mask" : ".*\(\\\\n\)\$")" = "\\n" ]; then
			printf -- "\n"
			printf -- "\n" >>"$its_file"
		fi
	)
	tbo() (
		tbo_ro()
		{
			v1=0; v2=0; v3=0; v4=0
			while read -r p _ rt; do
				[ "$p" -gt 5 ] && exit 1
				[ "$p" -eq 5 ] && [ "$rt" -ne 0377 ] && exit 1
				if [ "$p" -eq 5 ]; then
					for i in $v4 $v3 $v2 $v1; do
						printf -- "%b" "\0$(printf -- "%o" "$i")"
					done
					exit 0
				fi
				eval "v$p"=$(( 0$rt ))
			done
			exit 1
		}
		if [ "$(dd if=/proc/self/exe bs=1 count=1 skip=5 2>"$null" | b2d)" -eq 1 ]; then
			( cat; printf -- "%b" "\377" ) | cmp -l -- "$zeros" - 2>"$null" | tbo_ro
		else
			cat - 2>"$null"
		fi
	)
	b2d() (
		b2d_ro()
		{
			i=1; l=0; v=0; s=-8; ff=0
			while read -r p _ rt; do
				if [ "$ff" -eq 1 ]; then
					v=$(( v * 256 ))
					ff=255
					v=$(( v + ff ))
					i=$(( i + 1 ))
					ff=0
				fi
				while [ "$i" -lt "$p" ]; do
					v=$(( v * 256 ))
					i=$(( i + 1 ))
				done
				if [ "$rt" = 377 ] && [ $ff -eq 0 ]; then
					ff=1
					continue
				fi
				v=$(( v * 256 ))
				rt=$(( 0$rt ))
				v=$(( v + rt ))
				i=$(( p + 1 ))
			done
			printf -- "%d" $v
		}
		( cat; printf -- "%b" "\377" ) | cmp -l -- "$zeros" - 2>"$null" | b2d_ro
		return 0
	)
	get_data() ( dd if="$1" bs="$3" count=$(( ( $2 / $3 ) + 1 )) skip=1 2>"$null" | dd bs=1 count="$2" 2>"$null"; )
	str() (
		strlen()
		{
			s=1
			while read -r p l _; do
				[ "$p" -ne "$s" ] && printf -- "%u\n" "$(( s - 1 ))" && return
				s=$(( s + 1 ))
			done
			printf -- "%u\n" "$(( s - 1 ))"
		}
		l="$(get_data "$1" 256 "$2" | cmp -l -- - "$zeros" 2>"$null" | strlen)"
		[ -n "$l" ] && get_data "$1" "$l" "$2"
	)
	fdt32_align() { [ $(( $1 % 4 )) -gt 0 ] && printf -- "%u\n" $(( ( $1 + fdt32_size ) & ~3 )) || printf -- "%u\n" "$1"; }
	get_fdt32_be() (
		get_data "$1" 4 "$2" | b2d
	)
	get_fdt32_cpu() (
		get_data "$1" 4 "$2" | tbo | b2d
	)
	get_string() {
		n="$(printf -- "__fdt_string_%u" "$2")"
		f="$(set | sed -n -e "s|^\($n=\).*|\1|p")"
		if [ -z "$f" ]; then
			v="$(str "$1" "$2")"
			printf -- "%s=\"%s\"\n%s=\"\$%s\"\n" "$n" "$v" "$3" "$n"
		else
			v="$(set | sed -n -e "s|^$n=\(['\"]\?\)\(.*\)\1|\2|p")"
			printf -- "%s=\"\$%s\"\n" "$3" "$n"
		fi
	}
	indent() {
		printf -- "%s" "$(expr "$indent_template" : "\( \{$(( curr_indent * 4 ))\}\).*")"
	}
	incr_indent() { curr_indent=$(( curr_indent + 1 )); }
	decr_indent() { curr_indent=$(( curr_indent - 1 )); [ $curr_indent -lt 0 ] && curr_indent=0; }
	is_printable_string() (
		ro() {
			i=0
			while read -r p l _; do
				i=$(( i + 1 ))
				[ "$p" -gt "$i" ] && [ "$i" -eq 1 ] && return 1
				[ "$l" -lt 040 ] && return 1
				[ "$l" -gt 0176 ] && return 1
			done
			[ "$i" -eq 0 ] && [ "$1" -eq 1 ] && return 1;
			[ "$i" -lt $(( $1 - 1 )) ] && return 1
			return 0
		}
		get_data "$1" "$3" "$2" | cmp -l -- - "$zeros" 2>"$null" | ro "$3"
		return $?
	)
	get_hex32() (
		i=0
		while [ "$i" -lt "$3" ]; do
			v=$(get_fdt32_be "$img" $(( $2 + i )) )
			[ "$i" -gt 0 ] && printf -- " "
			printf -- "0x%08x" "$v"
			i=$(( i + fdt32_size ))
		done
	)
	get_hex8() (
		i=0
		while [ "$i" -lt "$3" ]; do
			v="$(get_data "$img" 1 $(( $2 + i )) | b2d)"
			[ "$i" -gt 0 ] && printf -- " "
			printf -- "%02x" "$v"
			i=$(( i + 1 ))
		done
	)
	get_file() (
		off=$2
		wr=$3
		dd if="$1" bs=4 skip=$(( off / 4 )) count=$(( ( 1024 - off % 1024 ) / 4 )) 2>"$null"
		off=$(( off + ( 1024 - off % 1024 ) ))
		wr=$(( wr - ( 1024 - $2 % 1024 ) ))
		[ $wr -le 0 ] && exit
		dd if="$1" bs=1024 skip=$(( off / 1024 )) count=$(( wr / 1024 )) 2>"$null"
		off=$(( off + wr ))
		wr=$(( wr % 1024 ))
		off=$(( off - wr ))
		[ $wr -le 0 ] && exit
		dd if="$1" bs=4 skip=$(( off / 4 )) count=$(( wr / 4 )) 2>"$null"
		off=$(( off + wr ))
		wr=$(( wr % 4 ))
		off=$(( off - wr ))
		[ $wr -le 0 ] && exit
		dd if="$img" bs=1 skip=$(( off )) count=$(( wr )) 2>"$null"
	)
	usage() {
		exec 1>&2
		printf -- "fitdump.sh - dissect a FIT image into .its and blob files\n\n"
		printf -- "Usage: %s [ -d | --debug ] [ -n | --no-its ] <fit-image>\n\n" "$0"
	}

	null="/dev/null"
	zeros="/dev/zero"
	its_name="image.its"
	its_file="$its_name"
	image_file_mask="image_%03u.bin"
	files=0
	curr_indent=0
	indent_template="$(dd if=$zeros bs=256 count=1 2>"$null" | tr '\000' ' ')"

	debug=0
	while [ "$(expr "$1" : "\(.\).*")" = "-" ]; do
		[ "$1" = "--" ] && shift && break

		if [ "$1" = "-d" ] || [ "$1" = "--debug" ]; then
			debug=1
			shift
		fi

		if [ "$1" = "-n" ] || [ "$1" = "--no-its" ]; then
			its_file="$null"
			shift
		fi
	done

	if [ "$debug" -eq 1 ] && [ -t 2 ]; then
		its_file="$its_name"
		exec 1>"$its_file"
	fi

	fdt_begin_node=1
	fdt_end_node=2
	fdt_prop=3
	fdt_nop=4
	fdt_end=9
	fdt32_size=4

	[ "$(dd if=/proc/self/exe bs=1 count=1 skip=5 2>"$null" | b2d)" -eq 1 ] && end="(LE)" || end="(BE)"

	img="$1"
	[ -f "$img" ] && fsize=$(( $(wc -c <"$img" 2>"$null" || printf -- "0") )) || fsize=0
	[ -f "$img" ] && [ "$fsize" -eq 0 ] && usage && exit 1
	msg "File: %s, size=%u\n" "$img" "$fsize"

	[ "$(dd if="$img" bs=4 count=1 2>"$null" | b2d)" = "218164734" ] || exit 1
	offset=0
	msg "Signature at offset 0x%02x: 0x%08x %s\n" "$offset" "$(dd if="$img" bs=4 count=1 2>"$null" | tbo | b2d)" "$end"

	offset=$(( offset + fdt32_size ))
	payload_size="$(get_fdt32_cpu "$img" "$offset")"
	msg "Overall length of data at offset 0x%02x: 0x%08x - dec.: %u %s\n" "$offset" "$payload_size" "$payload_size" "$end"

	offset=$(( offset + fdt32_size ))
	size=64
	msg "Data at offset 0x%02x, size %u:\n" "$offset" "$size"
	[ "$debug" -eq 1 ] && get_data "$img" "$size" "$offset" | hexdump -C | sed -n -e "1,$(( size / 16 ))p" 1>&2

	[ -f "$its_file" ] && rm -f "$its_file" 2>"$null"
	out "/dts-v1/;\n"

	offset=$(( offset + size ))
	fdt_magic="$(get_fdt32_be "$img" "$offset")"
	msg "FDT magic at offset 0x%02x: 0x%08x %s\n" "$offset" "$fdt_magic" "(BE)"
	[ "$fdt_magic" -ne 3490578157 ] && msg "Invalid FDT magic found.\n" && exit 1
	fdt_start=$offset
	out "// magic:\t\t0x%08x\n" "$fdt_magic"

	offset=$(( offset + fdt32_size ))
	fdt_totalsize="$(get_fdt32_be "$img" "$offset")"
	msg "FDT total size at offset 0x%02x: 0x%08x (dec.: %u) %s\n" "$offset" "$fdt_totalsize" "$fdt_totalsize" "(BE)"
	out "// totalsize:\t\t0x%x (%u)\n" "$fdt_totalsize" "$fdt_totalsize"

	offset=$(( offset + fdt32_size ))
	fdt_off_dt_struct="$(get_fdt32_be "$img" "$offset")"
	msg "FDT structure offset: 0x%08x (dec.: %u) %s\n" "$fdt_off_dt_struct" "$fdt_off_dt_struct" "(BE)"
	out "// off_dt_struct:\t0x%x\n" "$fdt_off_dt_struct"

	offset=$(( offset + fdt32_size ))
	fdt_off_dt_strings="$(get_fdt32_be "$img" "$offset")"
	msg "FDT strings offset: 0x%08x (dec.: %u) %s\n" "$fdt_off_dt_strings" "$fdt_off_dt_strings" "(BE)"
	out "// off_dt_strings:\t0x%x\n" "$fdt_off_dt_strings"

	offset=$(( offset + fdt32_size ))
	fdt_off_mem_rsvmap="$(get_fdt32_be "$img" "$offset")"
	msg "FDT memory reserve map offset: 0x%08x (dec.: %u) %s\n" "$fdt_off_mem_rsvmap" "$fdt_off_mem_rsvmap" "(BE)"
	out "// off_mem_rsvmap:\t0x%x\n" "$fdt_off_mem_rsvmap"

	offset=$(( offset + fdt32_size ))
	fdt_version="$(get_fdt32_be "$img" "$offset")"
	msg "FDT version at offset 0x%04x: 0x%08x (dec.: %u) %s\n" "$offset" "$fdt_version" "$fdt_version" "(BE)"
	out "// version:\t\t%u\n" "$fdt_version"

	offset=$(( offset + fdt32_size ))
	fdt_last_comp_version="$(get_fdt32_be "$img" "$offset")"
	msg "FDT last compatible version at offset 0x%04x: 0x%08x (dec.: %u) %s\n" "$offset" "$fdt_last_comp_version" "$fdt_last_comp_version" "(BE)"
	out "// last_comp_version:\t%u\n" "$fdt_last_comp_version"

	if [ "$fdt_version" -ge 2 ]; then
		offset=$(( offset + fdt32_size ))
		fdt_boot_cpuid_phys="$(get_fdt32_be "$img" "$offset")"
		msg "FDT physical CPU ID while booting at offset 0x%04x: 0x%08x (dec.: %u) %s\n" "$offset" "$fdt_boot_cpuid_phys" "$fdt_boot_cpuid_phys" "(BE)"
		out "// boot_cpuid_phys:\t0x%x\n" "$fdt_boot_cpuid_phys"

		if [ "$fdt_version" -ge 2 ]; then
			offset=$(( offset + fdt32_size ))
			fdt_size_dt_strings="$(get_fdt32_be "$img" "$offset")"
			msg "FDT size of strings block: 0x%08x (dec.: %u) %s\n" "$fdt_size_dt_strings" "$fdt_size_dt_strings" "(BE)"
			out "// size_dt_strings:\t0x%x\n" "$fdt_size_dt_strings"

			if [ "$fdt_version" -ge 17 ]; then
				offset=$(( offset + fdt32_size ))
				fdt_size_dt_struct="$(get_fdt32_be "$img" "$offset")"
				msg "FDT size of structure block: 0x%08x (dec.: %u) %s\n" "$fdt_size_dt_struct" "$fdt_size_dt_struct" "(BE)"
				out "// size_dt_struct:\t0x%x\n" "$fdt_size_dt_struct"
			fi
		fi
	fi
	out "\n"

	offset=$(( fdt_start + fdt_off_dt_struct ))
	data=$(get_fdt32_be "$img" "$offset")
	# shellcheck disable=SC2050
	while [ 1 -eq 1 ]; do
		case "$data" in
			("$fdt_begin_node")
				name_off="$(( offset + fdt32_size ))"
				eval "$(get_string "$img" $name_off "name")"
				[ -z "$name" ] && name="/"
				msg "Begin node at offset 0x%08x, name=%s\n" "$offset" "$name"
				offset=$(fdt32_align $(( offset + fdt32_size + ${#name} + 1 )) )
				out "%s%s {\n" "$(indent)" "$name"
				incr_indent
				;;
			("$fdt_end_node")
				msg "End node at offset 0x%08x\n" "$offset"
				offset=$(( offset + fdt32_size ))
				decr_indent
				out "%s};\n" "$(indent)"
				;;
			("$fdt_prop")
				value_size="$(get_fdt32_be "$img" $(( offset + fdt32_size )))"
				name_off="$(( fdt_start + fdt_off_dt_strings + $(get_fdt32_be "$img" $(( offset + ( 2 * fdt32_size ) )) ) ))"
				eval "$(get_string "$img" $name_off "name")"
				msg "Property node at offset 0x%08x, value size=%u, name=%s\n" "$offset" "$value_size" "$name"
				out "%s%s" "$(indent)" "$name"
				data_offset=$(( offset + 3 * fdt32_size ))
				if [ "$value_size" -gt 512 ]; then
					files=$(( files + 1 ))
					# shellcheck disable=SC2059
					file="$(printf -- "$image_file_mask\n" "$files")"
					out " = "
					out "/incbin/(\"%s\")" "$file"
					get_file "$img" "$data_offset" "$value_size" >"$file"
					msg "Created BLOB file '%s' with %u bytes of data from offset 0x%08x\n" "$file" "$value_size" "$data_offset"
				elif is_printable_string "$img" "$data_offset" "$value_size"; then
					eval "$(get_string "$img" $(( offset + 3 * fdt32_size )) "str")"
					if [ -n "$str" ]; then
						out " = "
						out "\"%s\"" "$str"
					fi
				elif [ $(( value_size % 4 )) -eq 0 ]; then
					out " = "
					out "<%s>" "$(get_hex32 "$img" "$data_offset" "$value_size")"
				else
					out " = "
					out "[%s]" "$(get_hex8 "$img" "$data_offset" "$value_size")"
				fi
				out ";\n"
				offset=$(fdt32_align $(( data_offset + value_size )) )
				;;
			("$fdt_nop")
				offset=$(( offset + fdt32_size ))
				;;
			("$fdt_end")
				msg "FDT end found at offset 0x%08x\n" "$offset"
				offset=$(( offset + fdt32_size ))
				break
				;;
		esac
		data=$(get_fdt32_be "$img" "$offset")
	done
)

dissect_fit_image "$@"