#!/bin/bash
#使用方法：如果有空格，用单引或者双引号括起来要查询的命令
#ES.sh   'xxxx'
#ES.sh   "xxxx"


##ES工作的IP和端口，自行修改
IP='8.131.65.73'
PORT='9200'


#要查询的字符串,请用单引号或者双引号括起来要查询的内容,防止出错
SEARCH_STRING=$1

##拼接查询query
STRING2='{   "query": {     "match": {       "command": {         "query": "'${SEARCH_STRING}'",         "minimum_should_match": "75%"       }     }   },  "_source": [ "command", "comment" ] }'

##根据模糊字符串   搜索近似命令,存储起来处理
#curl -uelastic:1234567# -XGET "http://$IP:$PORT/commandslist/_search?pretty" -H 'Content-Type: application/json' -d"$STRING2"  2>/dev/null  
curl -uelastic:1234567# -XGET "http://$IP:$PORT/commandslist/_search?pretty" -H 'Content-Type: application/json' -d"$STRING2"  2>/dev/null  | egrep -w '"command"|"comment"|"_id"'  > /tmp/tmp_command_comment.txt
#
##无匹配结果直接退出
LINES=`wc -l /tmp/tmp_command_comment.txt | awk -F ' ' '{print $1}'`
[ $LINES -eq 0 ] && echo '无匹配结果请重新输入' && exit 1


> /tmp/tmp_command.txt ##清空命令
> /tmp/tmp_comment.txt ##清空注释
> /tmp/tmp_id.txt ##清空注释


##读取每行，分割命令和注释
while read line
do 
     FLAG=`echo "${line}" | awk -F  ':' '{print $1}'`
     [ $FLAG == '"command"' ] && echo "${line}" >> /tmp/tmp_command.txt 
     [ $FLAG == '"comment"' ] && echo "${line}" >> /tmp/tmp_comment.txt
     [ $FLAG == '"_id"' ] && echo "${line}" >> /tmp/tmp_id.txt 
done < /tmp/tmp_command_comment.txt

##展示给用户所有命令，让用户选择
NUM=1
while read line
do 
     TMPCOMMAND=`echo $line | awk -F '"command" : '  '{print $2}'`
     echo -e "\033[42;37m $NUM    =>> ${TMPCOMMAND} \033[0m"
     COMMENT=`sed -n "${NUM}p" /tmp/tmp_comment.txt  | awk -F '"comment" : '  '{print $2}' | sed 's/.$//'` #输出文件的第n行
     echo -e "\033[44;37m ${COMMENT} \033[0m"
     ((NUM=$NUM+1))
done < /tmp/tmp_command.txt

##用户选择的命令行数和命令总数
echo ""
echo "----------------------------------------------------"
read -p "输入命令编号:" LINE_NUM
SUMARY=`wc -l /tmp/tmp_command.txt | awk -F ' ' '{print $1}'`

#给出所要命令
if [ "$LINE_NUM" -gt 0 -a $LINE_NUM -le $SUMARY  ] 2>/dev/null ;then 
    COMMAND=`sed -n "${LINE_NUM}p" /tmp/tmp_command.txt | awk -F '"command" : "'  '{print $2}'| sed 's/.$//'` #"command" : "ps ef | grep tomcat"#输出文件的第n行
    ID=`sed -n "${LINE_NUM}p" /tmp/tmp_id.txt | awk -F '"_id" : "'  '{print $2}'| sed 's/.$//'|sed 's/\"//'` #"command" : "ps ef | grep tomcat"#输出文件的第n行
    echo -e "\033[42;37m ${COMMAND} => ${ID}\033[0m"
    read -p "执行删除Y/y:" EXECUTE 
    [ "$EXECUTE" == "Y" -o "$EXECUTE" == "y" -o "$EXECUTE" == "yes" -o "$EXECUTE" == "YES" -o "$EXECUTE" == "Yes" ]  && curl -u elastic:1234567\# -XDELETE "http://$IP:$PORT/commandslist/_doc/${ID}"
else 
    echo '重新输入！！' 
fi





