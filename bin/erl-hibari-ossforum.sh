#!/bin/sh
# -*- mode:shell-script; coding:utf-8 -*-

erl +A 4 -name 'hibari_client@127.0.0.1' -setcookie hibari -pa $HIBARI_HOME/lib/*/ebin -pa $HOME/hands-on/lib/hibari_client_utils/ebin
