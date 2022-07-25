[[ "${_VANILLA_SH_IMPORT:+x}" == "x" ]] || return 0
_VANILLA_SH_IMPORT=yes

for i in "${BASH_SOURCE[@]}"; do
 echo "i:${i}"
done