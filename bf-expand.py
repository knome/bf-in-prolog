
import sys

print (
    sys
    .argv
    [1]
    .replace( '<', ' lt ' )
    .replace( '>', ' rt ' )
    .replace( ',', ' rd ' )
    .replace( '.', ' wr ' )
    .replace( '+', ' up ' )
    .replace( '-', ' dn ' )
    .replace( '[', ' sl ' )
    .replace( ']', ' el ' )
    .replace( '  ', ',' )
)
