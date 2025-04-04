 #!/bin/bash

 errors=0
 results=$(psql -v ON_ERROR_STOP=1 -f error_tests.sql )
 if [ "$?" -ne 0 ]; then
     exit 0
 else
     exit 1
 fi
