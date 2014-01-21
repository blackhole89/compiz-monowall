Monowall plugin for Compiz
==========================

tl;dr
-----

This plugin is a modification of the Desktop Wall plugin in Compiz 0.8.x that allows switching workspaces independently on each connected monitor. See [this video](https://www.youtube.com/watch?v=Uikx_2Y6CbQ) for a practical demonstration.

What and why
------------

All traditional, overlapping/floating, window managers (quantifying over those that I am aware of) handle the presence of multiple monitors by treating them as one huge virtual device.
One implication is that when switching workspaces, what is displayed on all 
output devices is changed simultaneously --- there is no natural way of performing an action corresponding to "I want my right monitor to keep displaying workspace 3 for now, but switch my left one from workspace 3 to workspace 2".
Yet, there is no obvious reason to dismiss a hypothetical workflow such as using a number of workspaces to jump between various parts of a large project's source code on one monitor, while using one workspace on the other monitor to display compiler warnings and another to hold, say, a `valgrind` instance.

Various approximations to this are possible with present tools, but all of them have some objective or subjective shortcomings:

 * Use sticky windows on some of the monitors. This requires either tedious manual sticking or overly general window rules, and dispels nearly all advantages of multiple workspaces on the monitor on which it is done.
 * Run separate X servers on each device. This is resource-heavier than necessary and causes several resource sharing problems, the most obvious being the one that clients can't be moved between the two monitors.
 * Use a window manager which supports per-monitor workspaces out of the box, such as `xmonad`. The developers of the aforementioned caution against extensively using floating windows, and generally there does not seem to be a single instance of such a WM that won't force a reconsideration of the user's desktop metaphor that is largely orthogonal to the question of multihead operation.

This plugin is a modification of the stock Desktop Wall plugin in Compiz 0.8.x that seeks to rectify the perceived shortcoming by adding the ability to move around independently on each connected output device, while not imposing any unnecessary constraints on existing behaviour. At the visceral level, this is achieved by aggressively exploiting the toroidal topology of the workspace wall and some undocumented but fairly consistent behaviour of the window sticking mechanism in Compiz's core and therefore probably will not cause much interoperation trouble with existing code.

PSA
---

This code has been tested by exactly one person on exactly one system and configuration as of the time of writing, and as such should be considered no-batteries-included alpha quality. Bug reports will be appreciated and pull requests for fixes received gratefully.

Binary packages
---------------

I have packaged amd64 binaries of a nearly initial version for Debian-like systems, compiled against compiz 0.8.8 and tested with compiz-mate only.

[click me](http://twilightro.kafuka.org/%7Eblackhole89/files/compiz-monowall_0.1.1+20140119-1_amd64.deb)

Known issues
------------

 * Moving to the workspace of a manually raised window doesn't always succeed. (WIP)
 * Sliding multiple workspaces at once exposes the underlying physical workspace geometry, sometimes resulting in the transition arrow and slide animation pointing in an unnatural direction. (WIP)

