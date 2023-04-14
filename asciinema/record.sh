echo "Going to start recording all demos"

#echo "kapp-controller demo"
#./kapp-controller/record.sh
#
#echo "kbld demo"
#./kbld/record.sh

array=( kapp-controller kbld )
for i in "${array[@]}"
do
	echo "$i demo"
  pushd "$i" || exit
  rm -f demo.cast
  asciinema rec demo.cast -c "./scenario.sh"
  popd || exit
done
