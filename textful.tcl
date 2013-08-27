#!/usr/bin/wish

# Textful - A minimalist cross-platform text editor.
# Copyright (C) 2010  Vasco Costa
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package require Tk

source syntax.tcl

set PROGNAME "Textful"
set VERSION "Alpha"
set AUTHORS "Copyright © 2010 Vasco Costa"

proc newFile {} {
    global PROGNAME
    if {[.text edit modified]} {
        set answer [tk_messageBox -message "File modified. Save changes?" -icon warning -type yesno]
        if {$answer == "yes"} {
            saveFile
        }
    }
    .text replace 1.0 end ""
    .text mark set insert 1.0
    .text yview moveto 0
    .text edit modified false
    wm title . "untitled - $PROGNAME"
    status
}

proc openFile {{fileName ""}} {
    global PROGNAME
    if {[.text edit modified]} {
        set answer [tk_messageBox -message "File modified. Save changes?" -icon warning -type yesno]
        if {$answer == "yes"} {
            saveFile
        }
    }
    if {$fileName == ""} {
        set fileName [tk_getOpenFile]
    }
    if {$fileName != ""} {
        if {[catch {set fileID [open $fileName r+]} error]} {
            tk_messageBox -message $error -icon error
        } else {
            .text replace 1.0 end ""
            .text insert end [read $fileID]
            .text mark set insert 1.0
            .text yview moveto 0
            .text edit modified false
            close $fileID
            wm title . "$fileName - $PROGNAME"
            updateStatus
            syntax ".text" 1.0 end [string range $fileName [expr {[string last "." $fileName] + 1}] end]
        }
    }
}

proc saveFile {} {
    global PROGNAME
    set fileName [lindex [split [wm title .] " - "] 0]
    if {$fileName != "untitled"} {
        set fileID [open $fileName w+]
        puts -nonewline $fileID [.text get 1.0 end-1c]
        close $fileID
        .text edit modified false
        wm title . "$fileName - $PROGNAME"
    } else {
        saveFileAs
    }
}

proc saveFileAs {{fileName ""}} {
    global PROGNAME
    if {$fileName == ""} {
        set fileName [lindex [split [wm title .] " - "] 0]
        set fileName [tk_getSaveFile -initialfile $fileName]
    }
    if {$fileName != ""} {
        if {[catch {set fileID [open $fileName w+]} error]} {
            tk_messageBox -message $error -icon error
        } else {
            puts -nonewline $fileID [.text get 0.0 end-1c]
            close $fileID
            .text edit modified false
            wm title . "$fileName - $PROGNAME"
        }
    }
}

proc find {{text ""}} {
    if {$text == ""} {
        toplevel .findwin
        wm title .findwin "Find"
        ttk::label .findwin.searchlbl -text "Search for:"
        ttk::entry .findwin.searchtxt -textvariable searchtxt -width 25
        ttk::button .findwin.closebtn -text "Close" -command {.text tag delete "found"; destroy .findwin}
        ttk::button .findwin.findbtn -text "Find" -command {if {[info exists ::searchtxt]} {find $::searchtxt}}
        grid columnconfigure .findwin 0 -weight 1
        grid rowconfigure .findwin 0 -weight 1
        grid .findwin.searchlbl -column 0 -row 0 -padx 20 -pady 20
        grid .findwin.searchtxt -column 1 -row 0 -padx 20 -pady 20
        grid .findwin.closebtn -column 1 -row 1 -padx 20 -pady 20 -sticky w
        grid .findwin.findbtn -column 1 -row 1 -padx 20 -pady 20 -sticky e
        focus .findwin.searchtxt
    } else {
        set index [split [.text search $text [.text index insert]] "."]
        if {[llength $index] != 0} {
            set line [lindex $index 0]
            set column [lindex $index 1]
            set nextColumn [expr {$column + [string length $text]}]
            .text tag delete "found"
            .text tag add "found" "$line.$column" "$line.$nextColumn"
            .text tag configure "found" -background "yellow"
            .text mark set insert "$line.$nextColumn"
        }
    }
}

proc about {} {
    global PROGNAME
    global VERSION
    global AUTHORS
    set answer [tk_dialog .dialog "About" "$PROGNAME $VERSION\n\n$AUTHORS" "" 0 Close]
}

proc command {command} {
    set splitCommand [split $command " "]
    switch [lindex $splitCommand 0] {
        "quit" {
            exit
        }
        "new" {
            newFile
            grid remove .command
        }
        "open" {
            openFile [lindex $splitCommand 1]
            grid remove .command
        }
        "save" {
            saveFile
            grid remove .command
        }
        "saveas" {
            saveFileAs [lindex $splitCommand 1]
            grid remove .command
        }
        "find" {
            find [lindex $splitCommand 1]
        }
        "goto" {
            set line [lindex $splitCommand 1]
            .text mark set insert "$line.0"
            grid remove .command
            focus .text
        }
    }
}

proc modified {} {
    if {[string index [wm title .] end] != "*"} {
        wm title . "[wm title .] *"
    }
}

proc quit {} {
    if {[.text edit modified]} {
        if {[.text edit modified]} {
            set answer [tk_messageBox -message "File modified. Save changes?" -icon warning -type yesno]
            if {$answer == "yes"} {
                saveFile
            }
        }
    }
    exit
}

proc closeWindow {} {
    if {[.text edit modified]} {
        if {[.text edit modified]} {
            set answer [tk_messageBox -message "File modified. Save changes?" -icon warning -type yesno]
            if {$answer == "yes"} {
                saveFile
            }
        }
    }
    exit
}

proc view {} {
    if {$::menubar} {
        . configure -menu .menubar
        focus .text
    } else {
        . configure -menu false
    }
    if {$::commandbar} {
        grid .command -column 0 -row 1 -columnspan 2 -sticky we
        focus .command
    } else {
        grid forget .command
    }
    if {$::statusbar} {
        grid .status -column 0 -row 2 -columnspan 2 -sticky e
        focus .text
    } else {
        grid forget .status
    }
}

proc updateStatus {} {
    set splitIndex [split [.text index insert] "."]
    set line [lindex $splitIndex 0]
    set column [lindex $splitIndex 1]
    set lines [.text count -lines 1.0 end]
    set characters [.text count -chars 1.0 end]
    set ::status "Lines: $lines Characters: $characters\tLn: $line Col: $column"
}

proc lineEdit {} {
    set splitIndex [split [.text index insert] "."]
    set line [lindex $splitIndex 0]
    set column [lindex $splitIndex 1]
    set fileName [lindex [split [wm title .] " - "] 0]
    if {$fileName != "untitled"} {
        syntax ".text" "$line.0" "$line.end" [string range $fileName [expr {[string last "." $fileName] + 1}] end]
    }
}

# WM

wm title . "untitled - $PROGNAME"
wm protocol . WM_DELETE_WINDOW {closeWindow}

if {[tk windowingsystem] == "x11"} {
    wm attributes . -zoomed true
} else {
    wm state . zoomed
}

# Menus

option add *tearOff 0

menu .menubar
menu .menubar.filemenu
menu .menubar.editmenu
menu .menubar.viewmenu
menu .menubar.helpmenu

. configure -menu .menubar

.menubar add cascade -menu .menubar.filemenu -label File -underline 0
.menubar add cascade -menu .menubar.editmenu -label Edit -underline 0
.menubar add cascade -menu .menubar.viewmenu -label View -underline 0
.menubar add cascade -menu .menubar.helpmenu -label Help -underline 0

.menubar.filemenu add command -label "New" -command "newFile" -underline 0 -accelerator "Ctrl-N"
.menubar.filemenu add command -label "Open..." -command "openFile" -underline 0 -accelerator "Ctrl-O"
.menubar.filemenu add separator
.menubar.filemenu add command -label "Save" -command "saveFile" -underline 0 -accelerator "Ctrl-S"
.menubar.filemenu add command -label "Save As..." -command "saveFileAs" -underline 5 -accelerator "Ctrl-A"
.menubar.filemenu add separator
.menubar.filemenu add command -label "Quit" -command "quit" -underline 0 -accelerator "Ctrl-Q"

.menubar.editmenu add command -label "Undo" -command ".text edit undo" -underline 0 -accelerator "Ctrl-Z"
.menubar.editmenu add command -label "Redo" -command ".text edit redo" -underline 0 -accelerator "Shift-Ctrl-Z"
.menubar.editmenu add separator
.menubar.editmenu add command -label "Cut" -command "event generate .text <<Cut>>" -underline 2 -accelerator "Ctrl-X"
.menubar.editmenu add command -label "Copy" -command "event generate .text <<Copy>>" -underline 0 -accelerator "Ctrl-C"
.menubar.editmenu add command -label "Paste" -command "event generate .text <<Paste>>" -underline 0 -accelerator "Ctrl-V"
.menubar.editmenu add command -label "Clear" -command "event generate .text <<Clear>>" -underline 0 -accelerator "Del"
.menubar.editmenu add separator
.menubar.editmenu add command -label "Find..." -command "find" -underline 0 -accelerator "Ctrl-F"

.menubar.viewmenu add checkbutton -label "Menubar" -command "view" -variable "menubar" -offvalue "false" -onvalue "true" -underline 0 -accelerator "Alt-M"
.menubar.viewmenu add checkbutton -label "Statusbar" -command "view" -variable "statusbar" -offvalue "false" -onvalue "true" -underline 0 -accelerator "Alt-S"
.menubar.viewmenu add checkbutton -label "Commandbar" -command "view" -variable "commandbar" -offvalue "false" -onvalue "true" -underline 0 -accelerator "Alt-C"

.menubar.helpmenu add command -label "Contents" -command "contents" -underline 0 -accelerator "F1"
.menubar.helpmenu add command -label "About" -underline 0 -command "about"

# Widgets

text .text -undo true -yscrollcommand {.scrollbar set}
ttk::scrollbar .scrollbar -command {.text yview}
ttk::entry .command -textvariable command
ttk::label .status -textvariable status

# Grid

grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1
grid .text -column 0 -row 0 -sticky nsew
grid .scrollbar -column 1 -row 0 -sticky nsew
grid .status -column 0 -row 2 -columnspan 2 -sticky e

focus .text

# Bindings

bind . <Control-n> {newFile}
bind . <Control-s> {saveFile}
bind . <Control-S> {saveFileAs}
bind . <Control-q> {quit}
bind . <Control-f> {find}
bind . <Control-o> {openFile}
bind .text <Control-o> {openFile; break}
bind .command <Return> {command $::command}
bind . <Alt-m> {if {!$::menubar} {. configure -menu .menubar; set ::menubar true; focus .text} else {. configure -menu false; set ::menubar false}}
bind . <Alt-c> {if {!$::commandbar} {grid .command -column 0 -row 1 -columnspan 2 -sticky we; set ::commandbar true; focus .command;} else {grid forget .command; set ::commandbar false; focus .text}}
bind . <Alt-s> {if {!$::statusbar} {grid .status -column 0 -row 2 -columnspan 2 -sticky e; set ::statusbar true; focus .text;} else {grid forget .status; set ::statusbar false}}
bind .text <<Modified>> {modified}
bind .text <Key> {updateStatus}
bind .text <space> {lineEdit}
bind .text <Return> {lineEdit}

set ::menubar true
set ::statusbar true
set ::commandbar false

updateStatus
