from fish_tracking import Aggregator
import sys

def print_help():
    print 'Help!'


def check_arguments():
    if len(sys.argv) < 2:
        print_help()
        sys.exit(-1)
    elif len(sys.argv) is 2 and sys.argv[1] == '-h':
        print_help()
        sys.exit(-1)
    else:
        command = sys.argv[1]
        other_args = sys.argv[2:]

def main():
    pass

if __name__ == '__main__':
    main()