#!/bin/bash
#直接配置成crontab任务即可
#例如：*/1 * * * *  sh    PATH_DIR/HISTORY_ADD_ES.sh

#说明：利用history记录的命令，将新产生的命令存储到ES中，供后期检索查询。因history是每次退出session后记录命令到~/.bash_history 下边，所以一开始可能检索不到，可以执行"history -a" 直接写一次~/.bash_history 文件，然后该定时任务会记录这些命令到ES中


#进入当前目录，获取到目录路径
cd `dirname $0`
SCRIPT_DIR=`pwd`

> /tmp/commands.txt #清空命令

touch /tmp/history.txt #创建一个文件
diff ~/.bash_history  /tmp/history.txt  -y -W 5000 -H --suppress-common-lines > /tmp/commands.txt #比较差异，新的命令要存储


#记录本次命令，下次用
\cp ~/.bash_history  /tmp/history.txt

#没有新命令退出
SUMARY=`wc -l /tmp/commands.txt | awk -F ' ' '{print $1}'`
[ $SUMARY -eq 0 ] && exit 1

#循环读取新命令，调用EA.sh存储到ES中
while read line
do
     #SAVE_TXT=`echo  "${line}" | awk -F '<' '{print $1}'|sed  's#	##g'`

     SAVE_TXT=`echo  "${line}" | awk -F '<' '{print $1}'|awk -F '	' '{print $1}'`
     a='\\"' ##转义双引号否则语法有问题
     COMMAND=`echo $SAVE_TXT | sed 's/"/'$a'/g'` ##要存储的命令

     echo $COMMAND
     $SCRIPT_DIR/EA.sh  "$COMMAND" "$COMMAND"
     #echo $SCRIPT_DIR
done < /tmp/commands.txt

