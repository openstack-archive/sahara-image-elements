#!/bin/bash -xe

find ./ -not -wholename \*.tox/\* -and \( -name \*.sh -or -wholename \*.d/\* -and -not -name \*.md -and -not -name \*.rst -and -not -name \*.py \) -print0 | xargs -0 bashate -v -i E006
