{}: ''
#!/usr/bin/env bash

MBOXES=(ranisavljevic)

STATUS=""
for m in "''${MBOXES[@]}"; do
  COUNT=$(find ~/mail/$m/inbox/new -type f 2> /dev/null | wc -l)
  if [ $COUNT -gt 0 ];
  then
    STATUS="$STATUS $m [$COUNT]"
  fi
done

if [ "" == "$STATUS" ];
then
  echo " inbox zero"
  exit 0
else
 echo "$STATUS"
  exit 33
fi
''
