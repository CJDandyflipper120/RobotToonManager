# -*- mode: TCL; fill-column: 75; tab-width: 8; coding: iso-latin-1-unix -*-
#
#	$Id: SWidget.tcl,v 1.2.2.1 2001/11/03 07:23:17 idiscovery Exp $
#
# SWidget.tcl --
#
# 	tixScrolledWidget: virtual base class. Do not instantiate
#	This is the core class for all scrolled widgets.
#
# Copyright (c) 1993-1999 Ioi Kim Lam.
# Copyright (c) 2000-2001 Tix Project Group.
#
# See the file "license.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#


tixWidgetClass tixScrolledWidget {
    -virtual true
    -classname TixScrolledWidget
    -superclass tixPrimitive
    -method {
    }
    -flag {
	-scrollbar -scrollbarspace
    }
    -configspec {
	{-scrollbar scrollbar Scrollbar both}
	{-scrollbarspace scrollbarSpace ScrollbarSpace {both}}
        {-sizebox sizeBox SizeBox 0}
    }
}

proc tixScrolledWidget:InitWidgetRec {w} {
    upvar #0 $w data

    tixChainMethod $w InitWidgetRec

    set data(x,first)   0
    set data(x,last)    0

    set data(y,first)   0
    set data(y,last)    0

    set data(lastSpec) ""
    set data(lastMW)   ""
    set data(lastMH)   ""
    set data(lastScbW) ""
    set data(lastScbH) ""

    set data(repack)	0
    set data(counter)   0

    set data(vsbPadY)   0
    set data(hsbPadX)   0
}

proc tixScrolledWidget:SetBindings {w} {
    upvar #0 $w data

    tixChainMethod $w SetBindings

    tixManageGeometry $data(pw:client) "tixScrolledWidget:ClientGeomProc $w"
    bind $data(pw:client) <Configure> \
	[list tixScrolledWidget:ClientGeomProc $w "" $data(pw:client)]

    tixManageGeometry $data(w:hsb) "tixScrolledWidget:ClientGeomProc $w"
    bind $data(w:hsb) <Configure> \
	[list tixScrolledWidget:ClientGeomProc $w "" $data(w:hsb)]

    tixManageGeometry $data(w:vsb) "tixScrolledWidget:ClientGeomProc $w"
    bind $data(w:vsb) <Configure> \
	[list tixScrolledWidget:ClientGeomProc $w "" $data(w:vsb)]

    bind $w <Configure> "tixScrolledWidget:MasterGeomProc $w"

    tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    set data(repack) 1
}

proc tixScrolledWidget:config-scrollbar {w value} {
    upvar #0 $w data
    global tcl_platform

    if {[lindex $value 0] == "auto"} {
	foreach xspec [lrange $value 1 end] {
	    case $xspec {
		{+x -x +y -y} {}
		default {
		    error "bad -scrollbar value \"$value\""
		}
	    }
	}
    } else {
	case $value in {
	    {none x y both} {}
	    default {
		error "bad -scrollbar value \"$value\""
	    }
	}
    }

    if {$data(-sizebox) && $tcl_platform(platform) == "windows"} {
        set data(-scrollbar) both
    }

    if {$data(repack) == 0} {
	set data(repack) 1
	tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    }
}	

proc tixScrolledWidget:config-scrollbarspace {w value} {
    upvar #0 $w data
  
    if {$data(repack) == 0} {
	set data(repack) 1
	tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    }
}	

proc tixScrolledWidget:config-sizebox {w value} {
  error "unimplemented"
}


#----------------------------------------------------------------------
#
#		 Scrollbar calculations
#
#----------------------------------------------------------------------
proc tixScrolledWidget:ClientGeomProc {w type client} {
    upvar #0 $w data

    if {$data(repack) == 0} {
	set data(repack) 1
	tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    }
}

proc tixScrolledWidget:MasterGeomProc {w} {
    upvar #0 $w data

    if {$data(repack) == 0} {
	set data(repack) 1
	tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    }
}

proc tixScrolledWidget:Configure {w} {
    if {![winfo exists $w]} {
	return
    }

    upvar #0 $w data

    if {$data(repack) == 0} {
	set data(repack) 1
	tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
    }
}

proc tixScrolledWidget:ScrollCmd {w scrollbar axis first last} {
    upvar #0 $w data

    $scrollbar set $first $last
}

# Show or hide the scrollbars as required.
#
# spec: 00 = need none
# spec: 01 = need y
# spec: 10 = need x
# spec: 11 = need xy
#
proc tixScrolledWidget:Repack {w} {
    tixCallMethod $w RepackHook
}

proc tixScrolledWidget:RepackHook {w} {
    upvar #0 $w data
    global tcl_platform

    if {![winfo exists $w]} {
	# This was generated by the <Destroy> event
	#
	return
    }

    set client $data(pw:client)

    # Calculate the size of the master
    #
    set mreqw [winfo reqwidth  $w]
    set mreqh [winfo reqheight $w]
    set creqw [winfo reqwidth  $client]
    set creqh [winfo reqheight $client]

    set scbW [winfo reqwidth  $w.vsb]
    set scbH [winfo reqheight $w.hsb]

    case $data(-scrollbarspace) {
	"x" {
	    incr creqh $scbH
	}
	"y" {
	    incr creqw $scbW
	}
	"both" {
	    incr creqw $scbW
	    incr creqh $scbH
	}
    }

    if {$data(-width) != 0} {
	set creqw $data(-width)
    }
    if {$data(-height) != 0} {
	set creqh $data(-height)
    }

    if {$mreqw != $creqw || $mreqh != $creqh } {
	if {![info exists data(counter)]} {
	    set data(counter) 0
	}
	if {$data(counter) < 50} {
	    incr data(counter)
	    tixGeometryRequest $w $creqw $creqh
	    tixWidgetDoWhenIdle tixScrolledWidget:Repack $w
	    set data(repack) 1
	    return
	}
    }

    set data(counter) 0
    set mw [winfo width  $w]
    set mh [winfo height $w]

    set cw [expr $mw - $scbW]
    set ch [expr $mh - $scbH]

    set scbx [expr $mw - $scbW]
    set scby [expr $mh - $scbH]

    # Check the validity of the sizes: if window was not mapped then
    # sizes will be below 1x1
    if {$cw < 1} {
	set cw 1
    }
    if {$ch < 1} {
	set ch 1
    }
    if {$scbx < 1} {
	set scbx 1
    }
    if {$scby < 1} {
	set scby 1
    }

    if {[lindex $data(-scrollbar) 0] == "auto"} {
	# Find out how we are going to pack the scrollbars
	#
	set spec [tixScrolledWidget:CheckScrollbars $w $scbW $scbH]

	foreach xspec [lrange $data(-scrollbar) 1 end] {
	    case $xspec {
		+x {
		    set spec [expr $spec | 10]
		}
		-x {
		    set spec [expr $spec & 01]
		}
		+y {
		    set spec [expr $spec | 01]
		}
		-y {
		    set spec [expr $spec & 10]
		}
	    }
	}
	if {$spec == 0} {
	    set spec 00
	}
	if {$spec == 1} {
	    set spec 01
	}
    } else {
	case $data(-scrollbar) in {
	    none {
		set spec 00
	    }
	    x {
		set spec 10
	    }
	    y {
		set spec 01
	    }
	    both {
		set spec 11
	    }
	}
    }


    if {$data(lastSpec)==$spec && $data(lastMW)==$mw && $data(lastMH)==$mh} {
	if {$data(lastScbW) == $scbW && $data(lastScbH) == $scbH} {
	    tixCallMethod $w PlaceWindow
	    set data(repack) 0
	    return
	}
    }

    set vsbH [expr $mh - $data(vsbPadY)]
    set hsbW [expr $mw - $data(hsbPadX)]

    if {$vsbH < 1} {
	set vsbH 1
    }
    if {$hsbW < 1} {
	set hsbW 1
    }

    case $spec in {
	"00" {
	    tixMoveResizeWindow $client 0 0 $mw $mh

	    tixMapWindow $client
    	    tixUnmapWindow $data(w:hsb)
	    tixUnmapWindow $data(w:vsb)
	}
	"01" {
	    tixMoveResizeWindow $client 0 0 $cw $mh
	    tixMoveResizeWindow $data(w:vsb) $scbx $data(vsbPadY) $scbW $vsbH

	    tixMapWindow $client
	    tixUnmapWindow $data(w:hsb)
	    tixMapWindow $data(w:vsb)
	}
	"10" {
	    tixMoveResizeWindow $client 0 0 $mw $ch
	    tixMoveResizeWindow $data(w:hsb) $data(hsbPadX) $scby $hsbW $scbH 

	    tixMapWindow $client
	    tixMapWindow $data(w:hsb)
	    tixUnmapWindow $data(w:vsb)
	}
	"11" {
	    set vsbH [expr $ch - $data(vsbPadY)]
	    set hsbW [expr $cw - $data(hsbPadX)]
	    if {$vsbH < 1} {
		set vsbH 1
	    }
	    if {$hsbW < 1} {
		set hsbW 1
	    }

	    tixMoveResizeWindow $client 0 0 $cw $ch
	    tixMoveResizeWindow $data(w:vsb) $scbx $data(vsbPadY) $scbW $vsbH
	    tixMoveResizeWindow $data(w:hsb) $data(hsbPadX) $scby $hsbW $scbH 
	    if {$data(-sizebox) && $tcl_platform(platform) == "windows"} {
	        tixMoveResizeWindow $data(w:sizebox) $scbx $scby $scbW $scbH
	    }

	    tixMapWindow $client
	    tixMapWindow $data(w:hsb)
	    tixMapWindow $data(w:vsb)
	    if {$data(-sizebox) && $tcl_platform(platform) == "windows"} {
	        tixMapWindow $data(w:sizebox)
	    }
	}
    }

    set data(lastSpec) $spec
    set data(lastMW)   $mw
    set data(lastMH)   $mh
    set data(lastScbW) $scbW
    set data(lastScbH) $scbH

    tixCallMethod $w PlaceWindow
    set data(repack) 0
}

proc tixScrolledWidget:PlaceWindow {w} {
    # virtual base function
}

#
# Helper function
#
proc tixScrolledWidget:NeedScrollbar {w axis} {
    upvar #0 $w data

    if {$data($axis,first) > 0.0} {
	return 1
    }

    if {$data($axis,last) < 1.0} {
	return 1
    }
    
    return 0
}

# Return whether H and V needs scrollbars in a list of two booleans
#
#
proc tixScrolledWidget:CheckScrollbars {w scbW scbH} {
    upvar #0 $w data

    set mW [winfo width  $w]
    set mH [winfo height $w]

    set info [tixCallMethod $w GeometryInfo $mW $mH]

    if {$info != ""} {
	set xSpec [lindex $info 0]
	set ySpec [lindex $info 1]

	set data(x,first)   [lindex $xSpec 0]
	set data(x,last)    [lindex $xSpec 1]

	set data(y,first)   [lindex $ySpec 0]
	set data(y,last)    [lindex $ySpec 1]
    }

    set needX [tixScrolledWidget:NeedScrollbar $w x]
    set needY [tixScrolledWidget:NeedScrollbar $w y]

    if {[winfo ismapped $w]==0} {
	return "$needX$needY"
    }

    if {$needX && $needY} {
	return 11
    }

    if {$needX == 0 && $needY == 0} {
	return 00
    }

    if {$needX} {
	set mH [expr $mH - $scbH]
    }
    if {$needY} {
	set mW [expr $mW - $scbW]
    }

    set info [tixCallMethod $w GeometryInfo $mW $mH]
    if {$info != ""} {
	set xSpec [lindex $info 0]
	set ySpec [lindex $info 1]

	set data(x,first)   [lindex $xSpec 0]
	set data(x,last)    [lindex $xSpec 1]

	set data(y,first)   [lindex $ySpec 0]
	set data(y,last)    [lindex $ySpec 1]
    }

    set needX [tixScrolledWidget:NeedScrollbar $w x]
    set needY [tixScrolledWidget:NeedScrollbar $w y]

    return "$needX$needY"
}

