
stats_line=`nl result.log | grep "Thread Stats" | awk '{print $1}'`
cat result.log | tail -n +$stats_line | head -n 3
