Feature:Create db using new_app cmd feature
 # @auther dyan@redhat.com
 # @case_id 509028, 509030
 Scenario Outline: Create mysql resources from imagestream via oc new-app
   Given I have a project
   When I run the :new_app client command with:
     | image_stream | <image_stream_name> |
     | env          | MYSQL_USER=user,MYSQL_PASSWORD=pass,MYSQL_DATABASE=db |
   Then the step should succeed
   Given I wait for the pod named "mysql-1-deploy" to die
    When I run the :deploy client command with:
      | deployment_config | mysql |
    Then the output should contain "mysql #1 deployed"   
   Given a pod becomes ready with labels:
     | deployment=mysql-1  |
   When I run the :get client command with:
      | resource | pods |
    Then the output should contain:
      | NAME            |
      | <%= pod.name %> |
    When I run the :describe client command with:
      | resource | pod             |
      | name     | <%= pod.name %> |
    Then the output should match:
      | Status:\\s+Running                        |
      | Ready\\s+True                             |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass -e "show databases" |
   Then the step should succeed
   And the output should contain "db"

   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass   -e "use db;create table test (name VARCHAR(20))" |
   Then the step should succeed
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass   -e "use db;insert into test VALUES('openshift')" |
   Then the step should succeed
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -uuser -ppass  -e "use db;select * from test" |
   Then the output should contain:
     | name |
     | openshift |

   Examples:
     | image_stream_name |
     | mysql:5.6         |
     | mysql:5.5         |




 # @auther dyan@redhat.com
 # @case_id 508979, 515707
 Scenario Outline: Create mongodb resources from imagestream via oc new-app
   Given I have a project
   When I run the :new_app client command with:
     | image_stream | <image_stream_name> |
     | env          | MONGODB_USER=user,MONGODB_PASSWORD=pass,MONGODB_DATABASE=db,MONGODB_ADMIN_PASSWORD=pass |
   Then the step should succeed
   Given I wait for the pod named "mongodb-1-deploy" to die
   When I run the :deploy client command with:
     | deployment_config | mongodb |
   Then the output should contain "mongodb #1 deployed"
   Given a pod becomes ready with labels:
     | deployment=mongodb-1  |
   When I run the :get client command with:
     | resource | pods |
   Then the output should contain:
     | NAME            |
     | <%= pod.name %> |
   When I run the :describe client command with:
     | resource | pod             |
     | name     | <%= pod.name %> |
   Then the output should match:
     | Status:\\s+Running         |
     | Ready\\s+True              |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mongo db -uuser -ppass --eval "db.db.insert({'name':'openshift'})" |
   Then the step should succeed
   When I execute on the pod:
     | bash           |
     | -c             |
     | mongo db -uuser -ppass --eval "printjson(db.db.findOne())" |
   Then the step should succeed
   And the output should contain:
     | name |
     | openshift |

   Examples:
     | image_stream_name |
     | mongodb:2.6       |
     | mongodb:2.4       |
