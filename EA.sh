#!/bin/bash
##两个参数请用单引号或者双引号括起来
##usage : 
#EA.sh 'xxx'   'xxx'  #传命令和注释即可

#ES工作的IP和端口个，自行需改
IP='8.131.65.73'
PORT='9200'
USER='elastic'
PASSWD='123456'
##过滤部分,可以过滤敏感命令、内容，自己处理
[ "$1" == ">" ] && exit 0 ##过滤某些命令，需要过滤哪些自己判断退出即可，将不会存储这些命令到ES中



#++++++++++++++++++++下方一般不需要改++++++++++++++++++++++++++++++==

b='\"' ##转义双引号否则语法有问题
NUM=`echo $1 | grep -w $b | wc -l`

if [ $NUM -ne 1 ];then
a='\\"' ##转义双引号否则语法有问题
COMMAND=`echo $1 | sed 's/"/'$a'/g'` ##要存储的命令
COMMENT=`echo $2 | sed 's/"/'$a'/g'` ##要存储的命令的注释
else
COMMAND=`echo $1` ##要存储的命令
COMMENT=`echo $2` ##要存储的命令的注释
fi
TIMESTAMP=`date +%s` ##默认记录的命令的时间戳

##先查询，如果已经有了就不往里边放了，查询字符串
FILTER='{   "from": 0,   "size": 10,   "query": {     "match": {       "command": {         "query": "'$COMMAND'",         "minimum_should_match": "100%"       }     }   },   "_source": [     "command"   ] }'
#可打开查看查询的结果
#echo $FILTER
#curl -u $USER:$PASSWD -XGET "http://8.210.23.127:9200/commandslist/_search?pretty" -H 'Content-Type: application/json' -d"$FILTER"
> /tmp/same.txt #清空上次的查询结果
#查询相似命令
curl -u $USER:$PASSWD -XGET "http://$IP:$PORT/commandslist/_search?pretty" -H 'Content-Type: application/json' -d"$FILTER"  2>/dev/null  | egrep -w '"command"' | awk -F '"command" : ' '{print $2}' > /tmp/same.txt


##处理查询结果，如果没有返回结果直接插入，返回结果的话仍然需要匹配下是否有一样的命令在ES中存储着，有的话就不存了，没有在存
LINES=`wc -l /tmp/same.txt | awk -F ' ' '{print $1}'`
if [ $LINES -eq 0 ];then
  QUERY='{   "command":"'$COMMAND'","tag":"","comment":"'$COMMENT'","timestamp":'$TIMESTAMP'}'
  curl  -u $USER:$PASSWD  -XPOST "http://$IP:$PORT/commandslist/_doc" -H 'Content-Type: application/json' -d"$QUERY"  #> /dev/null 2>&1
  #echo 'kc'
  exit 0
else
  while read line
  do
    #echo $line
    #echo $COMMAND
   [ "$line" != "\"$COMMAND\"" ] && echo "命令不同" > /dev/null  || exit 0 #任何一个相等都退出，不存储
  done < /tmp/same.txt
fi
#到这里代表确实没有相同的命令在ES中，需要存进去一份
QUERY='{   "command":"'$COMMAND'","tag":"","comment":"'$COMMENT'","timestamp":'$TIMESTAMP'}'
curl -u $USER:$PASSWD -XPOST "http://$IP:$PORT/commandslist/_doc" -H 'Content-Type: application/json' -d"$QUERY" > /dev/null 2>&1
