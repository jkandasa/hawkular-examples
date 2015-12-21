#!/bin/bash

HAWKULAR_URL="http://localhost:8080/hawkular/alerts"
DEMO_TENANT="my-organization"

HEADER_JSON="Content-Type: application/json"
HEADER_TENANT="Hawkular-Tenant: $DEMO_TENANT"
HEADER_AUTHORIZATION="Authorization: Basic amRvZTpwYXNzd29yZA=="

function create_email_action() {

  ## Check email plugin is installed

  local response=$(curl --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" $HAWKULAR_URL/plugins/email)
  
  if [ "$response" == "200" ]; 
  then
    echo "email plugin installed"
  else
    echo "email plugin not present - aborting...response code:$response"
    exit 1
  fi   

  ## Clean old email action

  response=$(curl --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_TENANT" $HAWKULAR_URL/actions/email/email-to-admin-group)

  if [ "$response" == "404" ];
  then
    echo "email-to-admin-group action is not present"
  else
    echo "deleting old email-to-admin-group action"
    response=$(curl -X DELETE --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_TENANT" $HAWKULAR_URL/actions/email/email-to-admin-group)
  fi
  
  ## Create new email action
 
  local action="{\"actionPlugin\":\"email\","
  action="$action \"actionId\":\"email-to-admin-group\","
  action="$action \"to\":\"admin-group@hawkular.org\","
  action="$action \"cc\":\"cc-group@hawkular.org\","
  action="$action \"template.hawkular.url\":\"http://www.hawkular.org\"}"

  local response=$(curl -X POST --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_JSON" -H "$HEADER_TENANT" --data "$action" $HAWKULAR_URL/actions)

  if [ "$response" == "200" ]; 
  then
    echo "email action created"
  else
    echo "email action not created - aborting...response code:$response"
    exit 1
  fi   
  
}

function create_trigger() {

  ## Clean old trigger definition
  
  local response=$(curl --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_TENANT" $HAWKULAR_URL/triggers/trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl)
  
  if [ "$response" == "404" ];
  then
    echo "trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl trigger is not present"
  else
    echo "deleting old trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl trigger"
    response=$(curl -X DELETE --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_TENANT" $HAWKULAR_URL/triggers/trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl)
  fi  
  
  ## Create new trigger
: '
  local trigger="{\"name\":\"trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl\","
  trigger="$trigger \"description\":\"Trigger for PoC\","
  trigger="$trigger \"actions\":{\"email\":[\"email-to-admin-group\"]},"
  trigger="$trigger \"firingMatch\":\"ALL\","
  trigger="$trigger \"autoResolveMatch\":\"ALL\","
  trigger="$trigger \"id\":\"trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl\","
  trigger="$trigger \"enabled\":true,"
  trigger="$trigger \"autoDisable\":false,"
  trigger="$trigger \"autoEnable\":false,"
  trigger="$trigger \"autoResolve\":false,"
  trigger="$trigger \"autoResolveAlerts\":false,"
  trigger="$trigger \"severity\":\"HIGH\"}"
'
  local trigger=`cat trigger.json`

  response=$(curl -i -X POST --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_JSON" -H "$HEADER_TENANT" --data "$trigger" $HAWKULAR_URL/triggers)
 
 if [ "$response" == "200" ]; 
  then
    echo "trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl trigger created"
  else
    echo "trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl trigger not created - aborting...response code:$response"
    exit 1
  fi   
    
}

function create_conditions() {

  ## Create first condition
 : ' 
  local cond1="{\"triggerMode\":\"FIRING\","
  cond1="$cond1 \"type\":\"THRESHOLD\","
  cond1="$cond1 \"dataId\":\"data-x\","
  cond1="$cond1 \"operator\":\"LT\","
  cond1="$cond1 \"threshold\":5}";
'
  local cond1=`cat condition.json`

  local response=$(curl -X PUT --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_JSON" -H "$HEADER_TENANT" --data "$cond1" $HAWKULAR_URL/triggers/trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl/conditions/FIRING)

  if [ "$response" == "200" ]; 
  then
    echo "condition1 created"
  else
    echo "condition1 not created - aborting...response code:$response"
    exit 1
  fi   
: '  
  ## Create a second conditions
  
  local cond2="{\"triggerMode\":\"FIRING\","
  cond2="$cond2 \"type\":\"THRESHOLD\","
  cond2="$cond2 \"dataId\":\"data-y\","
  cond2="$cond2 \"operator\":\"GT\","
  cond2="$cond2 \"threshold\":5}";
    
  response=$(curl -X POST --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_JSON" -H "$HEADER_TENANT" --data "$cond2" $HAWKULAR_URL/triggers/trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl/conditions)

  if [ "$response" == "200" ]; 
  then
    echo "condition2 created"
  else
    echo "condition2 not created - aborting...response code:$response"
    exit 1
  fi   
  
  ## Create a dampening condition
  
  local damp="{\"type\":\"STRICT\","
  damp="$damp \"evalTrueSetting\":2,"
  damp="$damp \"evalTotalSetting\":2}"
  
  response=$(curl -X POST --write-out %{http_code} --silent --output /dev/null -H "$HEADER_AUTHORIZATION" -H "$HEADER_JSON" -H "$HEADER_TENANT" --data "$damp" $HAWKULAR_URL/triggers/trigger-id-threshold-range-L_EXCLUSIVE-H_INCLUSIVE-R_false-bxdydgnl/dampenings)

  if [ "$response" == "200" ]; 
  then
    echo "dampening created"
  else
    echo "dampening not created - aborting...response code:$response"
    exit 1
  fi
'      
}

## Main

#create_email_action;
create_trigger;
create_conditions;
