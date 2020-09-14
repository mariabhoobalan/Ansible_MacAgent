#!/bin/bash
#--------------------------------------------------------------------------------------------------
# Script for starting or stopping the AppDynamics Machine Agent
#
#       Notes:
#               Edit all path names or agent options to suit your particular installation.
#
#               There may be differences in service scripts for CentOS/RedHat vs Ubuntu/Debian -
#                       adjust scripts accordingly
#
#--------------------------------------------------------------------------------------------------

# Edit the following parameters to suit your environment
TEMPSERVER=`uname -n`

#this is to remove fqdn from server
SERVER=$(echo $TEMPSERVER | awk -F '[.]' '{print $1}')

OS=`uname`
#MACHINE_AGENT_HOME=`pwd -P`      # -P parameters ignores symlinks and gives absolute path
MACHINE_AGENT_HOME="/opt/AppD/MachineAgent"

if [ "$OS" = "AIX" ]; then
	JAVA_BIN="/usr/java8_64/jre/bin/java"
else
	JAVA_BIN="$MACHINE_AGENT_HOME/jre/bin/java"
fi

MACHINE_AGENT_JAR="$MACHINE_AGENT_HOME/machineagent.jar"

# Optional command line machine agent properties
AGENT_OPTIONS="-Dappdynamics.agent.maxMetrics=2500"
AGENT_OPTIONS="$AGENT_OPTIONS -Xmx512m"

# == Controller Connection Properties
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.http.proxyHost={{ var_controller_host }}"
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.http.proxyPort={{ var_controller_port }}"

# == Machine Agent Identification Properties
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.applicationName={{ var_application_name }}"
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.tierName={{ var_tier_name }}"
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.nodeName={{ var_node_name }}"
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.nodeName=$SERVER"
AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.uniqueHostId=$SERVER"

# == Runtime Properties
#AGENT_OPTIONS="$AGENT_OPTIONS -Dappdynamics.agent.logging.dir="

# == Jetty Server Listener Properties
#AGENT_OPTIONS="$AGENT_OPTIONS -Dmetric.http.listener.port=<port>"
#AGENT_OPTIONS="$AGENT_OPTIONS -Dmetric.http.listener=true | false

# == Fix MQ Issue
AGENT_OPTIONS="$AGENT_OPTIONS -Djava.library.path=/usr/mqm/java/lib64"

# Do not edit below this line
MACHINE_AGENT_JAR="$MACHINE_AGENT_HOME/machineagent.jar"

start()
{
	PID=$(ps -ef | grep "java.*machineagent" | grep $MACHINE_AGENT_HOME | grep -v grep | awk '{print $2}')
	if ! [ "x$PID" = "x" ]; then
		echo "Machine Agent $MACHINE_AGENT_HOME - PID $PID - Already Running"
		exit 0
	else
        	echo "Machine Agent $MACHINE_AGENT_HOME - Starting"

		nohup $JAVA_BIN $AGENT_OPTIONS -jar $MACHINE_AGENT_JAR > /dev/null 2>&1 &

		PID=$(ps -ef | grep "java.*machineagent" | grep $MACHINE_AGENT_HOME | grep -v grep | awk '{print $2}')
		echo "Machine Agent $MACHINE_AGENT_HOME - PID $PID - Running"
	fi

}

stop()
{

	PID=$(ps -ef | grep "java.*machineagent" | grep $MACHINE_AGENT_HOME | grep -v grep | awk '{print $2}')
	if ! [ "x$PID" = "x" ]; then
		echo "Machine Agent $MACHINE_AGENT_HOME - PID $PID - Stopping"
		kill -9 $PID
	else
                echo "Machine Agent " $MACHINE_AGENT_HOME " - is NOT running"
		exit 1
	fi

        echo "Machine Agent $MACHINE_AGENT_HOME - Stopped"
}

status()
{

	PID=$(ps -ef | grep "java.*machineagent" | grep $MACHINE_AGENT_HOME | grep -v grep | awk '{print $2}')
	if ! [ "x$PID" = "x" ]; then
		echo "Machine Agent $MACHINE_AGENT_HOME - PID $PID - Running"
           else
                echo "Machine Agent " $MACHINE_AGENT_HOME " - is NOT running"
           fi
}

case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart)
                stop
                start
                ;;
        status)
                status
                ;;
        *)
                echo $"Usage: $0 {start|stop|restart|status}"
                exit 1
                ;;
esac
