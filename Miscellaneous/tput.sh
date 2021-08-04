#!/bin/sh

function warn_1 {
	tput sgr0; tput setb 4; tput bold
}

function warn_2 {
	tput sgr0; tput setaf 1
}

function normal_1 {
	tput sgr0; tput setb 2; tput bold
}

function normal_2 {
	tput sgr0; tput setaf 3; tput dim
}

function normal_3 {
	tput sgr0; tput setaf 6
}

function normal_4 {
	tput sgr0
}

function need_input {
	tput sgr0; tput setb 5; tput bold
}