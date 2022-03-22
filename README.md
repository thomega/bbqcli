# bbqcli -- a command line interface for WLANThermo

# CAVEAT
This documentation is *very* incomplete and the code is still in
*very* much in flux.  Command line options and their semantics can
change *without notice*.

# Purpose

A command line interface to the WLANThermo <https://wlanthermo.de/>
BBQ thermometer.

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
ocaml 4.08 or later (earlier versions can be made to work too),
see <https://ocaml.org/>.


### Libraries
1. `cmdliner`
2. `ocurl`
3. `yojson`
(all are readily available in opam, see <https://opam.ocaml.org/>).

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

# Man Pages
## bbqcli 


<h1 align="center">BBQCLI</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#COMMANDS">COMMANDS</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#EXAMPLES">EXAMPLES</a><br>
<a href="#FILES">FILES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#BUGS">BUGS</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli</b>
<i>COMMAND</i></p>

<h2>DESCRIPTION
<a name="DESCRIPTION"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Control a
WLANThermo Mini V3 on the command line using the HTTP
API.</p>

<h2>COMMANDS
<a name="COMMANDS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>alarm</b>
[<i>OPTION</i>] <b><br>
battery</b> [<i>OPTION</i>] <b><br>
control</b> [<i>OPTION</i>] <b><br>
data</b> [<i>OPTION</i>] <b><br>
info</b> [<i>OPTION</i>] <b><br>
monitor</b> [<i>OPTION</i>] <b><br>
pitmaster</b> [<i>OPTION</i>] <b><br>
settings</b> [<i>OPTION</i>] <b><br>
temperature</b> [<b>--all</b>]
[<b>--channel</b>=<i>N[,M...]</i>]
[<b>--channels</b>=<i>FROM-TO</i>] [<i>OPTION</i>]</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>EXAMPLES
<a name="EXAMPLES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli alarm -C
3-5 -c 9 -t 80-110 -p on</p>

<p style="margin-left:11%; margin-top: 1em">Sets the
temperature range on channels 3,4,5,9 to [80,110] and
switches on the push alert.</p>

<p style="margin-left:11%; margin-top: 1em">bbqcli
temperature -a</p>

<p style="margin-left:11%; margin-top: 1em">List the
temperatures and limits for all channels, including the
limits of disconnected channels.</p>

<p style="margin-left:11%; margin-top: 1em">bbqcli monitor
-w 60</p>

<p style="margin-left:11%; margin-top: 1em">Monitor all
temperatures every minute.</p>

<h2>FILES
<a name="FILES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">None, so
far.</p>

<h2>AUTHORS
<a name="AUTHORS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Thorsten Ohl
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>

<h2>BUGS
<a name="BUGS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Report bugs to
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>
<hr>
</html>

## bbqcli temperature


<h1 align="center">BBQCLI-TEMPERATURE</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#OPTIONS">OPTIONS</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#ENVIRONMENT">ENVIRONMENT</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">bbqcli-temperature</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli
temperature</b> [<b>--all</b>]
[<b>--channel</b>=<i>N[,M...]</i>]
[<b>--channels</b>=<i>FROM-TO</i>] [<i>OPTION</i>]</p>

<h2>OPTIONS
<a name="OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-a</b>,
<b>--all</b></p>

<p style="margin-left:17%;">Include the inactive
channels.</p>

<p style="margin-left:11%;"><b>-C</b> <i>FROM-TO</i>,
<b>--channels</b>=<i>FROM-TO</i></p>

<p style="margin-left:17%;">Select the channels in the
range <i>FROM-TO</i> (can be repeated).</p>

<p style="margin-left:11%;"><b>-c</b> <i>N[,M...]</i>,
<b>--channel</b>=<i>N[,M...]</i></p>

<p style="margin-left:17%;">Select the channel(s)
<i>N[,M...]</i> (can be repeated).</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-H</b>
<i>HOST</i>, <b>--host</b>=<i>HOST</i>
(absent=<b>wlanthermo</b> or <b>WLANTHERMO_HOST</b> env)</p>

<p style="margin-left:17%;">Connect to the host
<i>HOST</i>.</p>

<p style="margin-left:11%;"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<p style="margin-left:11%;"><b>-s</b> [<i>true/false</i>],
<b>--ssl</b>[=<i>true/false</i>] (default=<b>true</b>)
(absent=<b>false</b> or <b><br>
WLANTHERMO_SSL</b> env)</p>

<p style="margin-left:17%;">Use SSL to connect to the host.
This option should never be necessary or even used, because
WLANThermo does not understand SSL.</p>

<p style="margin-left:11%;"><b>-T</b> <i>SECONDS</i>,
<b>--timeout</b>=<i>SECONDS</i> (absent
<b>WLANTHERMO_TIMEOUT</b> env)</p>

<p style="margin-left:17%;">Wait only <i>SECONDS</i> for
response.</p>

<p style="margin-left:11%;"><b>-v</b> <i>VERBOSITY</i>,
<b>--verbosity</b>=<i>VERBOSITY</i>,
<b>--verbose</b>=<i>VERBOSITY</i> (absent=<b>0</b> or
<b><br>
WLANTHERMO_VERBOSITY</b> env)</p>

<p style="margin-left:17%;">Be more verbose.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>temperature</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>ENVIRONMENT
<a name="ENVIRONMENT"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">These
environment variables affect the execution of
<b>temperature</b>: <b><br>
WLANTHERMO_HOST</b></p>

<p style="margin-left:17%;">See option <b>--host</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_SSL</b></p>

<p style="margin-left:17%;">See option <b>--ssl</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_TIMEOUT</b></p>

<p style="margin-left:17%;">See option
<b>--timeout</b>.</p>


<p style="margin-left:11%;"><b>WLANTHERMO_VERBOSITY</b></p>

<p style="margin-left:17%;">See option
<b>--verbosity</b>.</p>

<h2>SEE ALSO
<a name="SEE ALSO"></a>
</h2>

 
<p style="margin-left:11%; margin-top: 1em">bbqcli(1)</p>
<hr>
</html>

## bbqcli alarm


<h1 align="center">BBQCLI-ALARM</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#OPTIONS">OPTIONS</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#ENVIRONMENT">ENVIRONMENT</a><br>
<a href="#FILES">FILES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>
<a href="#BUGS">BUGS</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">bbqcli-alarm</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli
alarm</b> [<i>OPTION</i>]</p>

<h2>DESCRIPTION
<a name="DESCRIPTION"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Change the
temperature limits and associated alarms on a WT Mini V3
using the HTTP API.</p>

<h2>OPTIONS
<a name="OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-a</b>,
<b>--all</b></p>

<p style="margin-left:17%;">Include the inactive
channels.</p>

<p style="margin-left:11%;"><b>-b</b> [<i>+|on|-|off</i>],
<b>--beep</b>[=<i>+|on|-|off</i>] (default=<b>on</b>)</p>

<p style="margin-left:17%;">Switch the beep alarm
on/off.</p>

<p style="margin-left:11%;"><b>-C</b> <i>FROM-TO</i>,
<b>--channels</b>=<i>FROM-TO</i></p>

<p style="margin-left:17%;">Select the channels in the
range <i>FROM-TO</i> (can be repeated).</p>

<p style="margin-left:11%;"><b>-c</b> <i>N[,M...]</i>,
<b>--channel</b>=<i>N[,M...]</i></p>

<p style="margin-left:17%;">Select the channel(s)
<i>N[,M...]</i> (can be repeated).</p>

<p style="margin-left:11%;"><b>-M</b> <i>MAX</i>,
<b>--max</b>=<i>MAX</i></p>

<p style="margin-left:17%;">Select the upper temperature
limit <i>MAX</i>. This takes precedence over upper limit of
a range specified in --temperature.</p>

<p style="margin-left:11%;"><b>-m</b> <i>MIN</i>,
<b>--min</b>=<i>MIN</i></p>

<p style="margin-left:17%;">Select the lower temperature
limit <i>MIN</i>. This takes precedence over the lower limit
of a range specified in --temperature.</p>

<p style="margin-left:11%;"><b>-p</b> [<i>+|on|-|off</i>],
<b>--push</b>[=<i>+|on|-|off</i>] (default=<b>on</b>)</p>

<p style="margin-left:17%;">Switch the push alarm
on/off.</p>

<p style="margin-left:11%;"><b>-t</b> <i>MIN-MAX</i>,
<b>--temperature</b>=<i>MIN-MAX</i>,
<b>--temp</b>=<i>MIN-MAX</i></p>

<p style="margin-left:17%;">Select the temperature range
<i>MIN-MAX</i>.</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-H</b>
<i>HOST</i>, <b>--host</b>=<i>HOST</i>
(absent=<b>wlanthermo</b> or <b>WLANTHERMO_HOST</b> env)</p>

<p style="margin-left:17%;">Connect to the host
<i>HOST</i>.</p>

<p style="margin-left:11%;"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<p style="margin-left:11%;"><b>-s</b> [<i>true/false</i>],
<b>--ssl</b>[=<i>true/false</i>] (default=<b>true</b>)
(absent=<b>false</b> or <b><br>
WLANTHERMO_SSL</b> env)</p>

<p style="margin-left:17%;">Use SSL to connect to the host.
This option should never be necessary or even used, because
WLANThermo does not understand SSL.</p>

<p style="margin-left:11%;"><b>-T</b> <i>SECONDS</i>,
<b>--timeout</b>=<i>SECONDS</i> (absent
<b>WLANTHERMO_TIMEOUT</b> env)</p>

<p style="margin-left:17%;">Wait only <i>SECONDS</i> for
response.</p>

<p style="margin-left:11%;"><b>-v</b> <i>VERBOSITY</i>,
<b>--verbosity</b>=<i>VERBOSITY</i>,
<b>--verbose</b>=<i>VERBOSITY</i> (absent=<b>0</b> or
<b><br>
WLANTHERMO_VERBOSITY</b> env)</p>

<p style="margin-left:17%;">Be more verbose.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>alarm</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>ENVIRONMENT
<a name="ENVIRONMENT"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">These
environment variables affect the execution of <b>alarm</b>:
<b><br>
WLANTHERMO_HOST</b></p>

<p style="margin-left:17%;">See option <b>--host</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_SSL</b></p>

<p style="margin-left:17%;">See option <b>--ssl</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_TIMEOUT</b></p>

<p style="margin-left:17%;">See option
<b>--timeout</b>.</p>


<p style="margin-left:11%;"><b>WLANTHERMO_VERBOSITY</b></p>

<p style="margin-left:17%;">See option
<b>--verbosity</b>.</p>

<h2>FILES
<a name="FILES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">None, so
far.</p>

<h2>AUTHORS
<a name="AUTHORS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Thorsten Ohl
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>

<h2>SEE ALSO
<a name="SEE ALSO"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli(1)</p>

<h2>BUGS
<a name="BUGS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Report bugs to
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>
<hr>
</html>

## bbqcli monitor


<h1 align="center">BBQCLI-MONITOR</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#OPTIONS">OPTIONS</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#ENVIRONMENT">ENVIRONMENT</a><br>
<a href="#FILES">FILES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>
<a href="#BUGS">BUGS</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">bbqcli-monitor</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli
monitor</b> [<i>OPTION</i>]</p>

<h2>DESCRIPTION
<a name="DESCRIPTION"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Continuously
monitor the WLANThermo.</p>

<h2>OPTIONS
<a name="OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-C</b>
<i>FROM-TO</i>, <b>--channels</b>=<i>FROM-TO</i></p>

<p style="margin-left:17%;">Select the channels in the
range <i>FROM-TO</i> (can be repeated).</p>

<p style="margin-left:11%;"><b>-c</b> <i>N[,M...]</i>,
<b>--channel</b>=<i>N[,M...]</i></p>

<p style="margin-left:17%;">Select the channel(s)
<i>N[,M...]</i> (can be repeated).</p>

<p style="margin-left:11%;"><b>-E</b> [<i>TIME</i>],
<b>--epoch</b>[=<i>TIME</i>] (default=)</p>

<p style="margin-left:17%;">Print time passed since
<i>TIME</i>. An empty string means now. Otherwise it must be
given in the format &quot;HH:MM&quot; or
&quot;HH:MM:SS&quot;.</p>

<p style="margin-left:11%;"><b>-F</b> [<i>FORMAT</i>],
<b>--format</b>[=<i>FORMAT</i>] (default=<b>time</b>)</p>

<p style="margin-left:17%;">Select the format of the
timestamp. One of &quot;time&quot;, &quot;date-time&quot; or
&quot;seconds&quot;.</p>

<p style="margin-left:11%;"><b>-n</b> <i>N</i>,
<b>--number</b>=<i>N</i> (absent=<b>0</b>)</p>

<p style="margin-left:17%;">Stop after <i>N</i>
measurements. A negative value or 0 will let the monitoring
contine indefinitely.</p>

<p style="margin-left:11%;"><b>-w</b> <i>SEC</i>,
<b>--wait</b>=<i>SEC</i> (absent=<b>10</b>)</p>

<p style="margin-left:17%;">Wait <i>SEC</i> seconds between
measurements. A negative value or 0 will be mapped to 1.</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-H</b>
<i>HOST</i>, <b>--host</b>=<i>HOST</i>
(absent=<b>wlanthermo</b> or <b>WLANTHERMO_HOST</b> env)</p>

<p style="margin-left:17%;">Connect to the host
<i>HOST</i>.</p>

<p style="margin-left:11%;"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<p style="margin-left:11%;"><b>-s</b> [<i>true/false</i>],
<b>--ssl</b>[=<i>true/false</i>] (default=<b>true</b>)
(absent=<b>false</b> or <b><br>
WLANTHERMO_SSL</b> env)</p>

<p style="margin-left:17%;">Use SSL to connect to the host.
This option should never be necessary or even used, because
WLANThermo does not understand SSL.</p>

<p style="margin-left:11%;"><b>-T</b> <i>SECONDS</i>,
<b>--timeout</b>=<i>SECONDS</i> (absent
<b>WLANTHERMO_TIMEOUT</b> env)</p>

<p style="margin-left:17%;">Wait only <i>SECONDS</i> for
response.</p>

<p style="margin-left:11%;"><b>-v</b> <i>VERBOSITY</i>,
<b>--verbosity</b>=<i>VERBOSITY</i>,
<b>--verbose</b>=<i>VERBOSITY</i> (absent=<b>0</b> or
<b><br>
WLANTHERMO_VERBOSITY</b> env)</p>

<p style="margin-left:17%;">Be more verbose.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>monitor</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>ENVIRONMENT
<a name="ENVIRONMENT"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">These
environment variables affect the execution of
<b>monitor</b>: <b><br>
WLANTHERMO_HOST</b></p>

<p style="margin-left:17%;">See option <b>--host</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_SSL</b></p>

<p style="margin-left:17%;">See option <b>--ssl</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_TIMEOUT</b></p>

<p style="margin-left:17%;">See option
<b>--timeout</b>.</p>


<p style="margin-left:11%;"><b>WLANTHERMO_VERBOSITY</b></p>

<p style="margin-left:17%;">See option
<b>--verbosity</b>.</p>

<h2>FILES
<a name="FILES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">None, so
far.</p>

<h2>AUTHORS
<a name="AUTHORS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Thorsten Ohl
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>

<h2>SEE ALSO
<a name="SEE ALSO"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli(1)</p>

<h2>BUGS
<a name="BUGS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Report bugs to
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>
<hr>
</html>

## bbqcli pitmaster


<h1 align="center">BBQCLI-PITMASTER</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#ENVIRONMENT">ENVIRONMENT</a><br>
<a href="#FILES">FILES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>
<a href="#BUGS">BUGS</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">bbqcli-pitmaster</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli
pitmaster</b> [<i>OPTION</i>]</p>

<h2>DESCRIPTION
<a name="DESCRIPTION"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Print the
pitmaster status.</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-H</b>
<i>HOST</i>, <b>--host</b>=<i>HOST</i>
(absent=<b>wlanthermo</b> or <b>WLANTHERMO_HOST</b> env)</p>

<p style="margin-left:17%;">Connect to the host
<i>HOST</i>.</p>

<p style="margin-left:11%;"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<p style="margin-left:11%;"><b>-s</b> [<i>true/false</i>],
<b>--ssl</b>[=<i>true/false</i>] (default=<b>true</b>)
(absent=<b>false</b> or <b><br>
WLANTHERMO_SSL</b> env)</p>

<p style="margin-left:17%;">Use SSL to connect to the host.
This option should never be necessary or even used, because
WLANThermo does not understand SSL.</p>

<p style="margin-left:11%;"><b>-T</b> <i>SECONDS</i>,
<b>--timeout</b>=<i>SECONDS</i> (absent
<b>WLANTHERMO_TIMEOUT</b> env)</p>

<p style="margin-left:17%;">Wait only <i>SECONDS</i> for
response.</p>

<p style="margin-left:11%;"><b>-v</b> <i>VERBOSITY</i>,
<b>--verbosity</b>=<i>VERBOSITY</i>,
<b>--verbose</b>=<i>VERBOSITY</i> (absent=<b>0</b> or
<b><br>
WLANTHERMO_VERBOSITY</b> env)</p>

<p style="margin-left:17%;">Be more verbose.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em"><b>pitmaster</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>ENVIRONMENT
<a name="ENVIRONMENT"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">These
environment variables affect the execution of
<b>pitmaster</b>: <b><br>
WLANTHERMO_HOST</b></p>

<p style="margin-left:17%;">See option <b>--host</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_SSL</b></p>

<p style="margin-left:17%;">See option <b>--ssl</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_TIMEOUT</b></p>

<p style="margin-left:17%;">See option
<b>--timeout</b>.</p>


<p style="margin-left:11%;"><b>WLANTHERMO_VERBOSITY</b></p>

<p style="margin-left:17%;">See option
<b>--verbosity</b>.</p>

<h2>FILES
<a name="FILES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">None, so
far.</p>

<h2>AUTHORS
<a name="AUTHORS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Thorsten Ohl
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>

<h2>SEE ALSO
<a name="SEE ALSO"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli(1)</p>

<h2>BUGS
<a name="BUGS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Report bugs to
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>
<hr>
</html>

## bbqcli control


<h1 align="center">BBQCLI-CONTROL</h1>

<a href="#NAME">NAME</a><br>
<a href="#SYNOPSIS">SYNOPSIS</a><br>
<a href="#DESCRIPTION">DESCRIPTION</a><br>
<a href="#OPTIONS">OPTIONS</a><br>
<a href="#COMMON OPTIONS">COMMON OPTIONS</a><br>
<a href="#EXIT STATUS">EXIT STATUS</a><br>
<a href="#ENVIRONMENT">ENVIRONMENT</a><br>
<a href="#FILES">FILES</a><br>
<a href="#AUTHORS">AUTHORS</a><br>
<a href="#SEE ALSO">SEE ALSO</a><br>
<a href="#BUGS">BUGS</a><br>

<hr>


<h2>NAME
<a name="NAME"></a>
</h2>



<p style="margin-left:11%; margin-top: 1em">bbqcli-control</p>

<h2>SYNOPSIS
<a name="SYNOPSIS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>bbqcli
control</b> [<i>OPTION</i>]</p>

<h2>DESCRIPTION
<a name="DESCRIPTION"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Modify the
pitmaster status.</p>

<h2>OPTIONS
<a name="OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">The options
--recall, --auto, --manual and --off are evaluated in that
order. For example, the command</p>

<p style="margin-left:11%; margin-top: 1em">bbqcli -a 99
-o</p>

<p style="margin-left:11%; margin-top: 1em">sets the target
temperature to 99 degrees and switches the pitmaster off.
<b><br>
-a</b> [<i>T</i>], <b>--auto</b>[=<i>T</i>]
(default=<b>-1.</b>)</p>

<p style="margin-left:17%;">Switch the pitmaster in auto
mode with target temperature <i>T</i>. Negative values keep
the old value unchanged.</p>

<p style="margin-left:11%;"><b>-c</b> <i>CH</i>,
<b>--channel</b>=<i>CH</i></p>

<p style="margin-left:17%;">Connect the pitmaster to the
channel number <i>CH</i>.</p>

<p style="margin-left:11%;"><b>-m</b> [<i>P</i>],
<b>--manual</b>[=<i>P</i>] (default=<b>-1</b>)</p>

<p style="margin-left:17%;">Switch the pitmaster in manual
mode with <i>P</i>% power. Negative values keep the old
value unchanged.</p>

<p style="margin-left:11%;"><b>-o</b>, <b>--off</b></p>

<p style="margin-left:17%;">Switch the pitmaster off.</p>

<p style="margin-left:11%;"><b>-p</b> <i>PM</i>,
<b>--pitmaster</b>=<i>PM</i> (absent=<b>0</b>)</p>

<p style="margin-left:17%;">Modify the pitmaster number
<i>PM</i>. This is never needed if there is only a single
pitmaster with number 0.</p>

<p style="margin-left:11%;"><b>-r</b>, <b>--recall</b></p>

<p style="margin-left:17%;">Switch the pitmaster back to
the last active state.</p>

<h2>COMMON OPTIONS
<a name="COMMON OPTIONS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>-H</b>
<i>HOST</i>, <b>--host</b>=<i>HOST</i>
(absent=<b>wlanthermo</b> or <b>WLANTHERMO_HOST</b> env)</p>

<p style="margin-left:17%;">Connect to the host
<i>HOST</i>.</p>

<p style="margin-left:11%;"><b>--help</b>[=<i>FMT</i>]
(default=<b>auto</b>)</p>

<p style="margin-left:17%;">Show this help in format
<i>FMT</i>. The value <i>FMT</i> must be one of <b>auto</b>,
<b>pager</b>, <b>groff</b> or <b>plain</b>. With
<b>auto</b>, the format is <b>pager</b> or <b>plain</b>
whenever the <b>TERM</b> env var is <b>dumb</b> or
undefined.</p>

<p style="margin-left:11%;"><b>-s</b> [<i>true/false</i>],
<b>--ssl</b>[=<i>true/false</i>] (default=<b>true</b>)
(absent=<b>false</b> or <b><br>
WLANTHERMO_SSL</b> env)</p>

<p style="margin-left:17%;">Use SSL to connect to the host.
This option should never be necessary or even used, because
WLANThermo does not understand SSL.</p>

<p style="margin-left:11%;"><b>-T</b> <i>SECONDS</i>,
<b>--timeout</b>=<i>SECONDS</i> (absent
<b>WLANTHERMO_TIMEOUT</b> env)</p>

<p style="margin-left:17%;">Wait only <i>SECONDS</i> for
response.</p>

<p style="margin-left:11%;"><b>-v</b> <i>VERBOSITY</i>,
<b>--verbosity</b>=<i>VERBOSITY</i>,
<b>--verbose</b>=<i>VERBOSITY</i> (absent=<b>0</b> or
<b><br>
WLANTHERMO_VERBOSITY</b> env)</p>

<p style="margin-left:17%;">Be more verbose.</p>

<h2>EXIT STATUS
<a name="EXIT STATUS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em"><b>control</b>
exits with the following status:</p>

<table width="100%" border="0" rules="none" frame="void"
       cellspacing="0" cellpadding="0">
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>0</p></td>
<td width="2%"></td>
<td width="80%">


<p>on success.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>123</p></td>
<td width="2%"></td>
<td width="80%">


<p>on indiscriminate errors reported on standard error.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>124</p></td>
<td width="2%"></td>
<td width="80%">


<p>on command line parsing errors.</p></td>
<td width="3%">
</td></tr>
<tr valign="top" align="left">
<td width="11%"></td>
<td width="4%">


<p>125</p></td>
<td width="2%"></td>
<td width="80%">


<p>on unexpected internal errors (bugs).</p></td>
<td width="3%">
</td></tr>
</table>

<h2>ENVIRONMENT
<a name="ENVIRONMENT"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">These
environment variables affect the execution of
<b>control</b>: <b><br>
WLANTHERMO_HOST</b></p>

<p style="margin-left:17%;">See option <b>--host</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_SSL</b></p>

<p style="margin-left:17%;">See option <b>--ssl</b>.</p>

<p style="margin-left:11%;"><b>WLANTHERMO_TIMEOUT</b></p>

<p style="margin-left:17%;">See option
<b>--timeout</b>.</p>


<p style="margin-left:11%;"><b>WLANTHERMO_VERBOSITY</b></p>

<p style="margin-left:17%;">See option
<b>--verbosity</b>.</p>

<h2>FILES
<a name="FILES"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">None, so
far.</p>

<h2>AUTHORS
<a name="AUTHORS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Thorsten Ohl
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>

<h2>SEE ALSO
<a name="SEE ALSO"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">bbqcli(1)</p>

<h2>BUGS
<a name="BUGS"></a>
</h2>


<p style="margin-left:11%; margin-top: 1em">Report bugs to
&lt;ohl@physik.uni-wuerzburg.de&gt;.</p>
<hr>
</html>

