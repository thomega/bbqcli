# bbqcli -- a command line interface for WLANThermo

# CAVEAT
This documentation is *very* incomplete and the code is still in
*very* much in flux.  Command line options and their semantics can
change *without notice*.

# Purpose

A command line interface to the WLANThermo <https://wlanthermo.de>
BBQ thermometer.

The HTTP API of the WLANThermo employed by `bbqcli` is documented at
<https://github.com/WLANThermo-nano/WLANThermo_ESP32_Software/wiki/HTTP>.
The software running on the ESP32 processor in the WLANThermo is hosted at GitHub
<https://github.com/WLANThermo-nano/WLANThermo_ESP32_Software>.

## Plans

- provide a local alternative to the public WLANThermo cloud and
  the the Telegram alerts
- a watchdog function that send alerts when the wifi connection
  breaks down
- scripting the pitmaster parameters
  - time dependent recipes
  - PID controller depending on more than one channel
  - PID tuning

## What Works

- checking and continuously reporting temperatures
- switching alarms on and off, changing the temperature ranges
- controlling the pitmaster

## What Doesn't Work Yet:

- scripting language (timing dependence and conditions) for the pitmaster
- acoustic alarms from the CLI
- adjusting PID parameters
- documentation (just a few automatically generated man pages)

# Installation

## Prerequisites

### Programming Language
ocaml 4.08 or later, see <https://ocaml.org>.

Readily available in opam, see <https://opam.ocaml.org>.

_NB: Earlier versions can be made to work too by adapting a few changed
names for standard library functions.  But since version 4.08.0 of ocaml
was already released in 2019, it's not worth the effort to maintain
compatibility with older releases until a specific need arises._

### Build System
1. dune

Readily available in opam, see <https://opam.ocaml.org>.

### Libraries
1. `cmdliner`
2. `ocurl`
3. `yojson`

All are readily available in opam, see <https://opam.ocaml.org>.

## Compilation
1. `make`
2. `make install`

# Notes on the Implementation

The program is structured as a single executable with subcommands
in the style of `git`.  This has two reasons:

- Most of the size of the executable comes from the libraries.  It is
  more efficient to link them only once.  I didn't want to rely on
  shared libraries, to be able to build static executables and move
  them easily to a small always-on device (NAS, Sheeva-Plug, etc.).
- I wanted to test the corresponding feature of the `cmdliner` library.

The program is split into the `cmdliner`-based CLI
<https://github.com/thomega/bbqcli/blob/main/bbqcli.ml>
that calls functions in the library
<https://github.com/thomega/bbqcli/blob/main/WLANThermo.ml>.

Note that the inface
<https://github.com/thomega/bbqcli/blob/main/WLANThermo.mli>
of this library is *not* yet stable and will change while I implement
additional features.

# Man Pages
## bbqcli 
<pre>
NAME
       bbqcli

SYNOPSIS
       bbqcli COMMAND …

DESCRIPTION
       Control a WLANThermo Mini V3 on the command line using the HTTP API.

COMMANDS
       alarm [OPTION]… 

       battery [OPTION]… 

       chef [--Recipe=RECIPE] [--recipe=FILE] [OPTION]… 

       control [OPTION]… 

       data [OPTION]… 

       info [OPTION]… 

       monitor [OPTION]… 

       pitmaster [OPTION]… 

       settings [OPTION]… 

       temperature [--all] [--channel=N[,M...]] [--channels=FROM-TO]
       [OPTION]… 


COMMON OPTIONS
       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

EXIT STATUS
       bbqcli exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

EXAMPLES
         bbqcli alarm -C 3-5 -c 9 -t 80-110 -p on

       Sets the temperature range on channels 3,4,5,9 to [80,110] and
       switches on the push alert.

         bbqcli temperature -a

       List the temperatures and limits for all channels, including the
       limits of disconnected channels.

         bbqcli monitor -w 60

       Monitor all temperatures every minute.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
## bbqcli temperature
<pre>
NAME
       bbqcli-temperature

SYNOPSIS
       bbqcli temperature [--all] [--channel=N[,M...]] [--channels=FROM-TO]
       [OPTION]… 

OPTIONS
       -a, --all
           Include the inactive channels.

       -C FROM-TO, --channels=FROM-TO
           Select the channels in the range FROM-TO (can be repeated).

       -c N[,M...], --channel=N[,M...]
           Select the channel(s) N[,M...] (can be repeated).

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       temperature exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of temperature:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

SEE ALSO
       bbqcli(1)

</pre>
## bbqcli alarm
<pre>
NAME
       bbqcli-alarm

SYNOPSIS
       bbqcli alarm [OPTION]… 

DESCRIPTION
       Change the temperature limits and associated alarms on a WT Mini V3
       using the HTTP API.

OPTIONS
       -a, --all
           Include the inactive channels.

       -b [+|on|-|off], --beep[=+|on|-|off] (default=on)
           Switch the beep alarm on/off.

       -C FROM-TO, --channels=FROM-TO
           Select the channels in the range FROM-TO (can be repeated).

       -c N[,M...], --channel=N[,M...]
           Select the channel(s) N[,M...] (can be repeated).

       -M MAX, --max=MAX
           Select the upper temperature limit MAX. This takes precedence over
           upper limit of a range specified in --temperature.

       -m MIN, --min=MIN
           Select the lower temperature limit MIN. This takes precedence over
           the lower limit of a range specified in --temperature.

       -p [+|on|-|off], --push[=+|on|-|off] (default=on)
           Switch the push alarm on/off.

       -t MIN-MAX, --temperature=MIN-MAX, --temp=MIN-MAX
           Select the temperature range MIN-MAX.

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       alarm exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of alarm:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

SEE ALSO
       bbqcli(1)

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
## bbqcli monitor
<pre>
NAME
       bbqcli-monitor

SYNOPSIS
       bbqcli monitor [OPTION]… 

DESCRIPTION
       Continuously monitor the WLANThermo.

OPTIONS
       -C FROM-TO, --channels=FROM-TO
           Select the channels in the range FROM-TO (can be repeated).

       -c N[,M...], --channel=N[,M...]
           Select the channel(s) N[,M...] (can be repeated).

       -E [TIME], --epoch[=TIME] (default=)
           Print time passed since TIME. An empty string means now. Otherwise
           it must be given in the format "HH:MM" or "HH:MM:SS".

       -F [FORMAT], --format[=FORMAT] (default=time)
           Select the format of the timestamp. One of "time", "date-time" or
           "seconds".

       -n N, --number=N (absent=0)
           Stop after N measurements. A negative value or 0 will let the
           monitoring contine indefinitely.

       -w SEC, --wait=SEC (absent=10 or WLANTHERMO_WAIT env)
           Wait SEC seconds between measurements. A negative value or 0 will
           be mapped to 1.

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       monitor exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of monitor:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

       WLANTHERMO_WAIT
           See option --wait.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

SEE ALSO
       bbqcli(1)

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
## bbqcli pitmaster
<pre>
NAME
       bbqcli-pitmaster

SYNOPSIS
       bbqcli pitmaster [OPTION]… 

DESCRIPTION
       Print the pitmaster status.

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       pitmaster exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of pitmaster:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

SEE ALSO
       bbqcli(1)

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
## bbqcli control
<pre>
NAME
       bbqcli-control

SYNOPSIS
       bbqcli control [OPTION]… 

DESCRIPTION
       Modify the pitmaster status.

OPTIONS
       The options --recall, --auto, --manual and --off are evaluated in that
       order. For example, the command

         bbqcli -a 99 -o

       sets the target temperature to 99 degrees and switches the pitmaster
       off.

       -a [T], --auto[=T] (default=-1.)
           Switch the pitmaster in auto mode with target temperature T.
           Negative values keep the old value unchanged.

       -c CH, --channel=CH
           Connect the pitmaster to the channel number CH.

       -m [P], --manual[=P] (default=-1)
           Switch the pitmaster in manual mode with P% power. Negative values
           keep the old value unchanged.

       -o, --off
           Switch the pitmaster off.

       -p PM, --pitmaster=PM (absent=0)
           Modify the pitmaster number PM. This is never needed if there is
           only a single pitmaster with number 0.

       -r, --recall
           Switch the pitmaster back to the last active state.

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       control exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of control:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

SEE ALSO
       bbqcli(1)

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
## bbqcli chef
<pre>
NAME
       bbqcli-chef

SYNOPSIS
       bbqcli chef [--Recipe=RECIPE] [--recipe=FILE] [OPTION]… 

DESCRIPTION
       Execute a recipe.

       NB: This is purely experimental at the moment and only used for
       figuring out features, abstract and concrete syntax. Don't expect
       anything to work.

OPTIONS
       -r FILE, --recipe=FILE
           Interpret the contents of file FILE as recipe. Can be repeated,
           but each file must be a syntactically valid recipe.

       -R RECIPE, --Recipe=RECIPE
           Interpret the string RECIPE as recipe. Can be repeated, but each
           string must be a syntactically valid recipe.

COMMON OPTIONS
       -H HOST, --host=HOST (absent=wlanthermo or WLANTHERMO_HOST env)
           Connect to the host HOST.

       --help[=FMT] (default=auto)
           Show this help in format FMT. The value FMT must be one of auto,
           pager, groff or plain. With auto, the format is pager or plain
           whenever the TERM env var is dumb or undefined.

       -s [true/false], --ssl[=true/false] (default=true) (absent=false or
       WLANTHERMO_SSL env)
           Use SSL to connect to the host. This option should never be
           necessary or even used, because WLANThermo does not understand
           SSL.

       -T SECONDS, --timeout=SECONDS (absent WLANTHERMO_TIMEOUT env)
           Wait only SECONDS for response.

       -v VERBOSITY, --verbosity=VERBOSITY, --verbose=VERBOSITY (absent=0 or
       WLANTHERMO_VERBOSITY env)
           Be more verbose.

EXIT STATUS
       chef exits with the following status:

       0   on success.

       123 on indiscriminate errors reported on standard error.

       124 on command line parsing errors.

       125 on unexpected internal errors (bugs).

ENVIRONMENT
       These environment variables affect the execution of chef:

       WLANTHERMO_HOST
           See option --host.

       WLANTHERMO_SSL
           See option --ssl.

       WLANTHERMO_TIMEOUT
           See option --timeout.

       WLANTHERMO_VERBOSITY
           See option --verbosity.

FILES
       None, so far.

AUTHORS
       Thorsten Ohl &lt;ohl@physik.uni-wuerzburg.de&gt;.

SEE ALSO
       bbqcli(1)

BUGS
       Report bugs to &lt;ohl@physik.uni-wuerzburg.de&gt;.

</pre>
