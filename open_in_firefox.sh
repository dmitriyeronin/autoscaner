#!/bin/bash

xsltproc -o result.html "$1"
firefox result.html
