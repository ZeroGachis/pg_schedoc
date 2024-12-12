 #!/bin/bash
 set -e
 errors=0
 results=$(psql -f error_tests.sql )
 [ "$?" -ne 0 ] || {
     echo "Test returned error code $?, this is what we want" 2>&1
     exit 0
     }
