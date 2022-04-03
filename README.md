# Command_Search_Via_ES
使用方法：
1、自行搭建Elasticsearch集群（单节点也可以），如果开放公网端口一定要配置认证加密
官网:https://www.elastic.co/guide/cn/elasticsearch/guide/current/running-elasticsearch.html
2、提前将脚本中使用到的索引创建好，mapping已经给出，在下边
3、将脚本中Elasticsearch的地址改成自己的，用户名和密码也改成自己的
4、测试即可，EA.sh 用来记录命令、ED.sh 用来删除命令 、ES.sh 用来搜索命令、EC.sh 也是用来搜索命令（搜索的字段不一样而已）







#脚本中用到索引的mapping
GET /commandslist/_mapping
{
  "commandslist" : {
    "mappings" : {
      "properties" : {
        "command" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "comment" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "tag" : {
          "type" : "text",
          "fields" : {
            "keyword" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "timestamp" : {
          "type" : "long"
        }
      }
    }
  }
}
