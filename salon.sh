#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -t --no-align"

echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

MAIN_MENU() {
  while true
  do
    SERVICES=$($PSQL -c "SELECT service_id, name FROM services ORDER BY service_id")

    while IFS="|" read -r ID NAME
    do
      if [[ -n $ID ]]
      then
        echo "$ID) $NAME"
      fi
    done <<< "$SERVICES"

    read SERVICE_ID_SELECTED || return

    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      echo -e "\nI could not find that service. What would you like today?"
      continue
    fi

    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

    if [[ -z $SERVICE_NAME ]]
    then
      echo -e "\nI could not find that service. What would you like today?"
      continue
    fi

    break
  done

  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE || return

  PHONE_SQL=${CUSTOMER_PHONE//\'/\'\'}

  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE phone='$PHONE_SQL'")

  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME || return

    NAME_SQL=${CUSTOMER_NAME//\'/\'\'}

    $PSQL -c "INSERT INTO customers(phone, name) VALUES('$PHONE_SQL', '$NAME_SQL')" > /dev/null
  fi

  CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone='$PHONE_SQL'")

  echo -e "\nWhat time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
  read SERVICE_TIME || return

  TIME_SQL=${SERVICE_TIME//\'/\'\'}

  INSERT_RESULT=$($PSQL -c "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL')")

  if [[ $INSERT_RESULT == "INSERT 0 1" ]]
  then
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

MAIN_MENU
