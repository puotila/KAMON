# librunscript.sh is a library of shell script functions that can be used in
# EC-Earth run scripts.
#
# Usage: source ./librunscript.sh

# Function info writes information to standard out.
#
# Usage: info MESSAGE ...
#
function info()
{
    echo "*II* $@"
}

# Function error writes information to standard out and exits the script with
# error code 1.
#
# Usage: error MESSAGE ...
#
function error()
{
    echo "*EE* $@"
    exit 1
}

# Function cleanup is called automatically by trapping signals. It is supposed
# to clean up after interruptions.
function cleanup()
{
    [[ -n "${tempfile:-}" ]] && if [ -r ${tempfile} ]
    then
        rm -f ${tempfile}
    fi
}
trap 'cleanup' EXIT SIGHUP SIGINT SIGTERM

# Function has_config checks it's arguments for matches in the $config variable
# and returns true (0) or false (1) accordingly. Optionally, the first argument
# can be either "all" (all arguments must match) or "any" (at least one
# argument must match). If the first argument is neither "all" nor "any", the
# function behaves like "all" was given as the first argument.
#
# Usage: has_config [all|any] ARGS ...
#
# Syntax rules:
#
# The $config variable takes a list of names (typically software components),
# separated by white spaces:
#
# config="foo bar baz"  # Specifies three components: 'foo', 'bar', and 'baz'
#
# It is possible to add comma-separated lists of options to components. The
# list is separated from the component by a colon:
#
# config="foo bar:qux,fred baz:plugh"  # Adds the options 'qux' and 'fred' to
#                                      # component 'bar' as well as option
#                                      # 'plugh' to  component 'baz'
#
# When using the has_config function to check the $config variable, it is
# important to list every component-option pair separately. To check for both
# the 'qux' and 'fred' options of component 'bar' in the above example, use:
#
# has_config bar:qux bar:fred && echo "Got it!"
#
function has_config()
{
    # If called without arguments, return false
    (( $# )) || return 1

    # If $config unset or empty, return false
    [[ -z "${config:-}" ]] && return 1

    local __c
    local __m

    # If first argument is "any" then only one of the arguments needs to match
    # to return true. Return false otherwise
    if [ "$1" == "any" ]
    then
        shift
        for __c in "$@"
        do
            for __m in $config
            do
                [[ "$__m" =~ "${__c%:*}" ]] && [[ "$__m" =~ "${__c#*:}" ]] && return 0
            done
        done
        return 1
    fi

    # If first argument is "all", or neither "any" nor "all", all arguments
    # must match to return true. Return false otherwise.
    [[ "$1" == "all" ]] && shift

    local __f
    for __c in "$@"
    do
        __f=0
        for __m in $config
        do
            [[ "$__m" =~ "${__c%:*}" ]] && [[ "$__m" =~ "${__c#*:}" ]] && __f=1
        done
        (( __f )) || return 1
    done
    return 0
}

# Function leap days calculates the number of leap days (29th of Februrary) in
# a time intervall between two dates.
#
# Usage leap_days START_DATE END_DATE
function leap_days()
{
    local ld=0
    local frstYYYY=$(date -ud "$1" +%Y)
    local lastYYYY=$(date -ud "$2" +%Y)

    set +e

    # Check first year for leap day between start and end date
    $(date -ud "${frstYYYY}-02-29" > /dev/null 2>&1) \
    && (( $(date -ud "$1" +%s) < $(date -ud "${frstYYYY}-03-01" +%s) )) \
    && (( $(date -ud "$2" +%s) > $(date -ud "${lastYYYY}-02-28" +%s) )) \
    && (( ld++ ))

    # Check intermediate years for leap day
    for (( y=(( ${frstYYYY}+1 )); y<=(( ${lastYYYY}-1 )); y++ ))
    do
        $(date -ud "$y-02-29" > /dev/null 2>&1) && (( ld++ ))
    done

    # Check last year (if different from first year) for leap day between start
    # and end date
    (( $lastYYYY > $frstYYYY )) \
    && $(date -ud "${lastYYYY}-02-29" > /dev/null 2>&1) \
    && (( $(date -ud "$1" +%s) < $(date -ud "${frstYYYY}-03-01" +%s) )) \
    && (( $(date -ud "$2" +%s) > $(date -ud "${lastYYYY}-02-28" +%s) )) \
    && (( ld++ ))

    set -e

    echo "$ld"
}
