for (( i=1; i<=35; i++ ))
do
    let "ost15 = i % 15"
    let "ost3 = i % 3"
    let "ost5 = i % 5"
    if [ "$ost15" -eq 0 ]; then  echo "FizzBuzz  $i"
      elif [ "$ost3" -eq 0 ]; then  echo "Fizz  $i"
      elif [ "$ost5" -eq 0 ]; then  echo "Buzz  $i"
      else echo "$i"
    fi
done