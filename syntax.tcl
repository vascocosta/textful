# Tcl/Tk

set tclKeywords { \
    after apend apply array auto_execok auto_import \
    auto_load auto_mkindex auto_mkindex_old auto_qualify auto_reset bgerror \
    binary break catch cd chan clock close concat continue dde dict encoding \
    eof error eval exec exit expr fblocked fconfigure fcopy file fileevent \
    filename flush for foreach format gets glob global history http if incr \
    info interp join lappend lassign lindex linsert list llength load lrange \
    lrepeat lreplace lreverse lsearch lset lsort mathfunc mathop memory \
    msgcat namespace open package parray pid pkg_mkIndex platform proc puts \
    pwd re_syntax read refchan regexp registry regsub rename return scan \
    seek set socket source split string subst switch Tcl tcl_endOfWord \
    tcl_findLibrary tcl_startOfNextWord tcl_startOfPreviousWord \
    tcl_WordBreakAfter tcl_WordBreakBefore tcltest tclvars tell time tm \
    trace unknown unload unset update uplevel upvar variable vwait while \
}
set tclStrings {{"[^"]*"}}
set tclComments {{#.*}}

# Python

set pythonKeywords { \
    and as assert break class continue def del elif else except exec finally \
    for from global if import in is lambda not or pass print raise return try \
    while with yield None self\
}
set pythonStrings {{"[^"]*"} {'[^']*'}}
set pythonComments {{#.*}}

proc highlight {textwidget start finish keywords strings comments} {
    set sindices {}
    set findices {}
    set tagname "keywords"
    set color "red"
    foreach keyword $keywords {
        set currentlength 0
        foreach i [$textwidget search -all -regexp -count lengths "\\m$keyword\\M" $start $finish] { 
            set split [split $i "."]
            lappend sindices $split
            set split [lreplace $split 1 1 [expr {[lindex $split 1] + [lindex $lengths $currentlength]}]]
            lappend findices $split
            foreach x $sindices z $findices {
                $textwidget tag add $tagname [join $x "."] [join $z "."]
            }
            $textwidget tag configure $tagname -foreground $color
            incr currentlength
        }
    }
    set sindices {}
    set findices {}
    set tagname "strings"
    set color "darkgreen"
    foreach string $strings {
        set currentlength 0
        foreach i [$textwidget search -all -regexp -count lengths $string $start $finish] {
            set split [split $i "."]
            lappend sindices $split
            set split [lreplace $split 1 1 [expr {[lindex $split 1] + [lindex $lengths $currentlength]}]]
            lappend findices $split
            foreach x $sindices z $findices {
                $textwidget tag add $tagname [join $x "."] [join $z "."]
            }
            $textwidget tag configure $tagname -foreground $color
            incr currentlength
        }
    }
    set sindices {}
    set findices {}
    set tagname "comments"
    set color "blue"
    foreach comment $comments {
        set currentlength 0
        foreach i [$textwidget search -all -regexp -count lengths $comment $start $finish] {
            set split [split $i "."]
            lappend sindices $split
            set split [lreplace $split 1 1 [expr {[lindex $split 1] + [lindex $lengths $currentlength]}]]
            lappend findices $split
            foreach x $sindices z $findices {
                $textwidget tag add $tagname [join $x "."] [join $z "."]
            }
            $textwidget tag configure $tagname -foreground $color
            incr currentlength
        }
    }
}

proc syntax {textWidget start finish extension} {
    global tclKeywords
    global tclStrings
    global tclComments
    global pythonKeywords
    global pythonStrings
    global pythonComments
    switch $extension {
        "tcl" {
            set keywords $tclKeywords
            set strings $tclStrings
            set comments $tclComments
        }
        "py" {
            set keywords $pythonKeywords
            set strings $pythonStrings
            set comments $pythonComments
        }
    }
    if {[info exists keywords] || [info exists strings] || [info exists comments]} {
        highlight $textWidget $start $finish $keywords $strings $comments
    }
}
