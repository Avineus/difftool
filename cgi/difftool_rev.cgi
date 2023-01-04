#!/bin/sh 


#
# Command to execute
# ssh bng-junos-d011 /homes/antonyr/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr
# ssh bng-junos-d011 /homes/antonyr/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr status
# ssh bng-junos-d011 /homes/antonyr/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr diff
#

SSH=autossh

fn_print_header()
{
    echo "Content-type: text/html"
    echo ""
    echo ""

    echo '<html>'
    echo '<head>'
    echo '<title>svn diff tool</title>'
    echo '<style type="text/css">'
    echo '</style>'
    echo '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">'
    echo '</head>'
    echo "<pre>"
    echo "<body>"

}

fn_print_footer()
{
    echo "</pre>"
    echo "</body>"
    echo '</html>'
}

fn_print_form() 
{
    echo '<form name="info" action="difftool_rev.cgi" method="get">'
    #echo '<br>'
    echo "Revision Number:  <input type='text' name='rev' value=$REVISION>"
    echo '<br>'
    echo '<input type="submit" value="submit">'
    echo '</form>'
    echo '<br>'
    echo '<hr>'
    echo '<br>'
}


fn_print_query_string()
{
    saveIFS=$IFS
    IFS='=&'
    parm=($QUERY_STRING)
    IFS=$saveIFS

    REVISION=${parm[1]}
    REVISION_PREV=$(($REVISION -1 ))

    #echo "$QUERY_STRING"
    #echo "$REVISION:$REVISION_PREV"

}

fn_fill_defaults()
{
    REVISION=0
    REVISION_PREV=0
}

fn_execute_svn_cmd()
{
    CMD=$1
    HTML=$2

    if [ -z "$CMD" ]; then
        echo "Error: No svn command"
        return
    fi

    #echo "CMD:$CMD"
    #echo "HTML:$HTML"
    SERVER=svl-junos-d011
    LOCAL_SB_NAME=.
    USR_NAME=antonyr
    URL=https://svl-svn.juniper.net/svn/junos-2009/

    if [ -n "$SERVER" ] && [ -n "$LOCAL_SB_NAME" ] && [ -n "$USR_NAME" ]; then
        if [ "$HTML" = "yes" ] ; then
            ssh -o StrictHostKeyChecking=no $SERVER /homes/antonyr/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD $URL | /homes/antonyr/public_html/cgi/diff2html.sh 2>/dev/null
        else
            ssh -o StrictHostKeyChecking=no $SERVER /homes/antonyr/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD $URL
        fi
        ERROR=$?
        if [ "$ERROR" -ne 0 ] ; then
            echo "Fixme err $ERROR"
        fi
        #ssh $SERVER /homes/antonyr/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD > /tmp/tmp.out
        #cat /tmp/tmp.out
        #| /homes/antonyr/public_html/cgi/diff2html
        echo "<hr>"
    #else
        #echo "Empty $SERVER $LOCAL_SB_NAME $USR_NAME"
    fi

}

fn_execute_svn_log()
{
    fn_execute_svn_cmd "COMMAND log -r $REVISION"
}

fn_execute_svn_status()
{
    fn_execute_svn_cmd "COMMAND diff --summarize -c $REVISION"
}

fn_execute_svn_diff()
{
    fn_execute_svn_cmd "COMMAND diff -c $REVISION" "yes"
}

##
##  HTML Code starts here
##

fn_print_header

fn_print_query_string

#fn_fill_defaults

fn_print_form

fn_execute_svn_log

fn_execute_svn_status

fn_execute_svn_diff

fn_print_footer

