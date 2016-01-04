Feature: Add env variables to image feature
 # @auther dyan@redhat.com
 # @case_id 473390
 Scenario: Add env variables to mysql-55-rhel7 image
   Given I have a project
   When I run the :create client command with:
     | f | https://raw.githubusercontent.com/openshift-qe/v3-testfiles/master/image/db-templates/mysql-55-env-var-test.json |
   Then the step should succeed
   And I run the :get client command with:
     | resource | template |
   Then the step should succeed
   And the output should contain:
     | mysql-ephemeral   MySQL database service, without persistent storage. |
   And I run the :new_app client command with:
     | template | mysql-ephemeral |
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
     | env \| grep MYSQL |
   Then the step should succeed
   And the output should contain:
     | MYSQL_LOWER_CASE_TABLE_NAMES=1 |
     | MYSQL_FT_MIN_WORD_LEN=5        |
     | MYSQL_MAX_CONNECTIONS=100      |
     | MYSQL_AIO=1                    |
     | MYSQL_FT_MAX_WORD_LEN=15       |


   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'lower_case_table_names';" |
   Then the step should succeed
   And the output should contain:
     | lower_case_table_names |
     | 1                      |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'max_connections';" |
   Then the step should succeed
   And the output should contain:
     | max_connections |
     | 100             |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'ft_min_word_len';" |
   Then the step should succeed
   And the output should contain:
     | ft_min_word_len |
     | 5               |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'ft_max_word_len';" |
   Then the step should succeed
   And the output should contain:
     | ft_max_word_len |
     | 15              |
   When I execute on the pod:
     | bash           |
     | -c             |
     | mysql -h $MYSQL_SERVICE_HOST -u$MYSQL_USER -p$MYSQL_PASSWORD   -e "SHOW VARIABLES LIKE 'innodb_use_native_aio';" |
   Then the step should succeed
   And the output should contain:
     | innodb_use_native_aio |
     | ON                    |

