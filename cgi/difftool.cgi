#!/bin/sh 


#
# Command to execute
# ssh bng-junos-d011 /homes/shapathj/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr
# ssh bng-junos-d011 /homes/shapathj/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr status
# ssh bng-junos-d011 /homes/shapathj/public_html/cgi/svndiff_shell.cgi ANT_DIAG_RAIN antonyr diff
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
    echo '<form name="info" action="difftool.cgi" method="get">'
    echo "User:    <input type='text' name='usr' value=$USR_NAME>"
    echo "Sandbox: <input type='text' name='sb' value=$LOCAL_SB_NAME>"
    #echo '<br>'
    echo "Server:  <input type='text' name='svr' value=$SERVER>"
    #echo 'Password:     <input type="password" name="pwd">'
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

    USR_NAME=${parm[1]}
    LOCAL_SB_NAME=`/homes/antonyr/public_html/cgi/urldecode.sh ${parm[3]}`
    SERVER=${parm[5]}

    #echo "$QUERY_STRING"

    #echo "SERVER=$SERVER"
    #echo "SB_NAME=$LOCAL_SB_NAME"
    #echo "USR_NAME=$USR_NAME"

}

fn_fill_defaults()
{
    if [ -z "$SERVER" ]; then
        SERVER=bng-junos-d011
    fi

    if [ -z "$USR_NAME" ]; then
        USER_NAME=antonyr
    fi
    if [ -z "$LOCAL_SB_NAME" ]; then
        LOCAL_SB_NAME=ANT_DIAG_RAIN
    fi
}

fn_execute_svn_cmd()
{
    CMD=$1
    HTML=$2
    if [ -z "$CMD" ]; then
        echo "Error: No svn command"
        return
    fi


    if [ -n "$SERVER" ] && [ -n "$LOCAL_SB_NAME" ] && [ -n "$USR_NAME" ]; then
        if [ "$HTML" = "yes" ] ; then
            ssh -o StrictHostKeyChecking=no $SERVER /homes/shapathj/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD | /homes/shapathj/public_html/cgi/diff2html.sh 2>/dev/null
        else
            ssh -o StrictHostKeyChecking=no $SERVER /homes/shapathj/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD  | grep -v "^?"
        fi
        ERROR=$?
        if [ "$ERROR" -ne 0 ] ; then
            echo "Fixme err $ERROR"
            echo "ssh $SERVER /homes/shapathj/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD"
        fi
        #ssh $SERVER /homes/antonyr/public_html/cgi/svndiff_shell.cgi $LOCAL_SB_NAME $USR_NAME $CMD > /tmp/tmp.out
        #cat /tmp/tmp.out
        #| /homes/antonyr/public_html/cgi/diff2html
        echo "<hr>"
    #else
        #echo "Empty $SERVER $LOCAL_SB_NAME $USR_NAME"
    fi

}

fn_execute_svn_status()
{
    fn_execute_svn_cmd "status"
}

fn_execute_svn_diff()
{
    fn_execute_svn_cmd "diff" "yes"
}

##
##  HTML Code starts here
##

fn_print_header

fn_print_query_string

#fn_fill_defaults

fn_print_form

fn_execute_svn_status

fn_execute_svn_diff

fn_print_footer

