#!/bin/sh

## Change these configuration variables. They should probably match server.properties
## Leave them blank if you think I'm a good guesser.
SERVER_ROOT=
SERVER_PROPERTIES=
LOCAL_PORT=
LOCAL_IP=localhost
MINECRAFT_JAR=
MINECRAFT_LOG=
SESSION=
WAIT_TIME=
SERVER_USER=
LAUNCH=
START_LOCKFILE=
IDLE_LOCKFILE=
PLAYERS_FILE=

## NB: This default may not be sensible
JAVAOPTS=
JAVAOPTS=${JAVAOPTS:--Xmx2G -Xms1G -server -XX:+UseG1GC -XX:MaxGCPauseMillis=50 \
  -XX:ParallelGCThreads=2 -XX:+DisableExplicitGC -XX:+AggressiveOpts -d64}

## TODO: Currenently not used. Need to recompute size and UTF-16BE
## encode the message, which is annoying
MESSAGE=

## Here be defaults
SERVER_ROOT=${SERVER_ROOT:-/srv/tekkit}
SERVER_PROPERTIES=${SERVER_PROPERTIES:-$SERVER_ROOT/server.properties}
LOCAL_PORT=${LOCAL_PORT:-$(sed -n 's/^server-port=\([0-9]*\)$/\1/p' ${SERVER_PROPERTIES})}
LOCAL_IP=${LOCAL_IP:-$(sed -n 's/^server-ip=\([0-9]*\)$/\1/p' ${SERVER_PROPERTIES})}
MINECRAFT_JAR=${MINECRAFT_JAR:-$SERVER_ROOT/Tekkit.jar}
MINECRAFT_LOG=${MINECRAFT_LOG:-$SERVER_ROOT/server.log}
SESSION=${SESSION:-Minecraft}
MESSAGE=${MESSAGE:-Just a moment please}
WAIT_TIME=${WAIT_TIME:-600}
SERVER_USER=${SERVER_USER:-tekkit}
LAUNCH=${LAUNCH:-/etc/tekkit-on-demand/launch.sh}
START_LOCKFILE=${START_LOCKFILE:-/tmp/startingtekkit}
IDLE_LOCKFILE=${IDLE_LOCKFILE:-/tmp/idleingtekkit}
PLAYERS_FILE=${PLAYERS_FILE:-/tmp/tekkitplayers}

## Advanced configuration. You may not need to change this.

debug() {
  #echo "$1"
  echo -n ""
}

## Define this function to start the minecraft server. This should start
## the server, and do any pre or post processing steps you might need.

## This command will be run in a screen session to communicate with the
## server
## This command is run as $SERVER_USER
start() {
  # TODO: Or maybe some tekkit-start should be in here.
  /usr/bin/java $JAVAOPTS -jar $MINECRAFT_JAR nogui 2>&1 \
    | sed -n -e 's/^.*There are \([0-9]*\)\/[0-9] players.*$/\1/' -e 't M' -e 'b' -e ": M w $PLAYERS_FILE" -e 'd' \
    | grep -v -e "INFO" -e "Can't keep up"
}

## Define this function to stop the minecraft server. This should stop
## the server, and do any pre or post processing steps you might need.

## This command will be run by your crontab.
stop() {
  screen -S $SESSION -p 0 -X stuff 'stop\15'
  debug "Shit's going down"
}

## Define this function to return true if and only if the server has no
## players online. The server will shut down if this returns true twice
## in a $WAIT_TIME.
## This command is run by your crontab.
idle() {
  # TODO: Maybe some of this should be in tekkit-idle.
  echo -n "" > ${PLAYERS_FILE}
  debug `cat ${PLAYERS_FILE}`
  screen -S $SESSION -p 0 -X stuff 'list\15'
  players=`tail -n 1 ${PLAYERS_FILE} | tr -d [:cntrl:]`
  while [ -z ${players} ]; do
    sleep 1
    players=`tail -n 1 ${PLAYERS_FILE} | tr -d [:cntrl:]`
  done
  debug "There are ${players} players"
  if [ "0" = "${players}" ]; then
    debug "Idle"
    true
  else
    debug "Not idle"
    false
  fi
}
