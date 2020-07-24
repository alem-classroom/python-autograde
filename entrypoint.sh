#!/bin/bash

# script runs with 
#   api-key = to send result to the api
#   course-test-url = private repo with tests
#   user-key = token to download private repos

# script will clone student solution and tests
# move tests to student lessons dirs
# run tests for each lesson
# send result to the api with lesson name, course name, username

# GITHUB_REPOSITORY = url to the repo 
# GITHUB_ACTOR = username

# python-introduction-template
# variables-and-types
#  - hello.py
 
# test-python-introduction !private
# test-variables-and-types
#  - hello_test.py

set -ue

API_KEY=$1
COURSE_TEST_URL=$2
USER_KEY=$3

export INPUT_GRADE="good job, contact me @frozen6heart"
export INPUT_URL="good job, contact me @frozen6heart"
export INPUT_TOKEN="good job, contact me @frozen6heart"

# JOB=$(curl -s https://api.github.com/repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/jobs )
# ID=$(echo $JOB | jq '.jobs[0].id' )
# LOGS_URL="https://github.com/alem-classroom/student-python-introduction-Zulbukharov/commit/$GITHUB_SHA/checks/$ID/logs"
# echo $LOGS_URL

TEST=${COURSE_TEST_URL##*/test-}
TEST_FULL="$TEST/test-"
SOLUTION="solution"


SOLUTION_URL="https://github.com/${GITHUB_REPOSITORY}"
TEST_URL="https://$USER_KEY@github.com/${COURSE_TEST_URL}"

printf "📝 hello $GITHUB_ACTOR\n"
printf "⚙️  building enviroment\n"
printf "⚙️  cloning solutions\n"
git clone $SOLUTION_URL $SOLUTION
git clone $TEST_URL $TEST
printf "⚙️  cloning finished\n"

# copy test file to solution dirs
find $TEST -type f -name '*test*' -print0 | xargs -n 1 -0 -I {} bash -c 'set -e; f={}; cp $f $0/${f:$1}' $SOLUTION ${#TEST_FULL}

# list of all dirs
z=$(find $TEST -mindepth 1 -maxdepth 1 -type d -name "test*" -print0 | xargs -n 1 -0 -I {} bash -c 't={}; printf "${t##$0/test-}\n"' $TEST)

send_result(){
    data=$(jq -aRs . <<< ${5})
    # apikey user lesson status logs 
    curl -s -X POST "https://lrn.dev/api/service/grade" -H "x-grade-secret: ${1}" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"username\":\"${2}\", \"lesson\":\"${3}\", \"status\": \"${4}\", \"logs\": ${data}}"
    echo ""
}

pip install pytest > /dev/null

for LESSON_NAME in $z
do
    # pip install -r "$SOLUTION/$LESSON_NAME/requirements.txt"
    set +e
    result=$(pytest "$SOLUTION/$LESSON_NAME")
    last="$?"
    echo "${result}"
    set -e
    if [[ $last -eq 0 ]]; then
        printf "✅ $LESSON_NAME-$TEST passed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "done" "${result}"
    else
        printf "🚫 $LESSON_NAME-$TEST failed\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "failed" "${result}"
    fi

done

printf "👾👾👾 done 👾👾👾\n"
