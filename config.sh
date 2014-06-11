#!/bin/sh

## Change these configuration variables. They should probably match server.properties
## Leave them blank if you think I'm a good guesser.
SERVER_ROOT=
SERVER_ROOT=${SERVER_ROOT:-/srv/tekkit}

SERVER_PROPERTIES=
SERVER_PROPERTIES=${SERVER_PROPERTIES:-$SERVER_ROOT/server.properties}

LOCAL_PORT=
LOCAL_PORT=${LOCAL_PORT:-$(sed -n 's/^server-port=\([0-9]*\)$/\1/p' ${SERVER_PROPERTIES})}

LOCAL_IP=
LOCAL_IP=${LOCAL_IP:-$(sed -n 's/^server-ip=\([0-9]*\)$/\1/p' ${SERVER_PROPERTIES})}

MINECRAFT_JAR=
MINECRAFT_JAR=${MINECRAFT_PATH:-$SERVER_ROOT/Tekkit.jar}

MINECRAFT_LOG=
MINECRAFT_LOG=${MINECRAFT_PATH:-$SERVER_ROOT/server.log}

## NB: This default may not be sensible
JAVAOPTS=
JAVAOPTS=${JAVAOPTS:--Xmx2G -Xms1G -server -XX:+UseG1GC -XX:MaxGCPauseMillis=50 \
  -XX:ParallelGCThreads=2 -XX:+DisableExplicitGC -XX:+AggressiveOpts -d64}

SESSION=
SESSION=${SESSION:-Minecraft}

## TODO: Currenently not used. Need to recompute size and UTF-16BE
## encode the message, which is annoying
MESSAGE=
MESSAGE=${MESSAGE:-Just a moment please}

WAIT_TIME=
WAIT_TIME=${WAIT_TIME:-600}

SERVER_USER=
SERVER_USER=${SERVER_USER:-tekkit}

LAUNCH=
LAUNCH=${LAUNCH:-/etc/tekkit-on-demand/launch.sh}

START_LOCKFILE=
START_LOCKFILE=${START_LOCKFILE:-/tmp/startingtekkit}

IDLE_LOCKFILE=
IDLE_LOCKFILE=${START_LOCKFILE:-/tmp/idleingtekkit}

PLAYERS_FILE=
PLAYERS_FILE=${PLAYERS_FILE:-/tmp/tekkitplayers}

debug() {
  #echo "$1"
  echo -n ""
}
## You may not need to change this.

## Define this function to start the minecraft server. This should start
## the server, and do any pre or post processing steps you might need.

## This command will be run in a screen session to communicate with the
## server
start() {
  /usr/bin/java $JAVAOPTS -jar $MINECRAFT_JAR nogui 2>&1 \
    | sed -n -e 's/^.*There are \([0-9]*\)\/[0-9] players.*$/\1/' -e 't M' -e 'b' -e ": M w $PLAYERS_FILE" -e 'd' \
    | grep -v -e "INFO" -e "Can't keep up"
}

## You may not need to change this.

## Define this function to start the minecraft server. This should start
## the server, and do any pre or post processing steps you might need.

## This command will be run by crontab to stop the server.
stop() {
  screen -S $SESSION -p 0 -X stuff 'stop\15'
  debug "Shit's going down"
}

## Define this function to return true if and only if the server has no
## players online. The server will shut down
idle() {
  screen -S $SESSION -p 0 -X stuff 'list\15'
  while ! lsof | grep $PLAYERS_FILE; do
    sleep 1
  done
  cat $PLAYERS_FILE | tr -d [:cntrl:] > $PLAYERS_FILE
  players=`cat $PLAYERS_FILE`
  debug "There are $players players"
  if [ "0" = "$players" ]; then
    debug "Idle"
    true
  else
    debug "Not idle"
    false
  fi
}
