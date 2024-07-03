# print file $TMT_DATA_FILE in format:
# line number | line content

cat $TMT_DATA_FILE | awk '{print NR "| " $0}'
