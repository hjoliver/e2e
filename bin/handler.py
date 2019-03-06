#!/usr/bin/env python3

"""
A generic Cylc event handler.

"""

import sys
import json
from inspect import cleandoc


def main():
    """
    A generic Cylc event handler: it takes one or more kwargs and pretty-prints
    them.

    USAGE:
       handler.py key1=val1 key2=val2 ...

    Can be partnered with the generic cylc_kafka_consumer external trigger
    function, for triggering downstream suites.

    """

    if len(sys.argv) < 2:
        print("ERROR: one or more args required.\n")
        print(cleandoc(main.__doc__))
        sys.exit(1)

    if 'help' in sys.argv[1]:
        print(cleandoc(main.__doc__))
        sys.exit(0)

    # Construct a dict from kwargs.
    dmsg = dict([k.split('=') for k in sys.argv[1:]])

    # Pretty print the dict to stdout.
    print(json.dumps(dmsg, indent=2))


if __name__ == "__main__":
    main()
