echo "Going to start recording all demos"

if (( $# > 0 )) ; then
  array=( "$@" )
else
  array=( kapp-controller kbld secretgen-controller)
fi

for i in "${array[@]}"
do
	echo "$i demo"
  pushd "$i" || exit
  rm -f demo.cast
  asciinema rec demo.cast -c "./scenario.sh"
  if [[ -f "rollback.sh" ]]; then
      ./rollback.sh
  fi
  popd || exit
done
