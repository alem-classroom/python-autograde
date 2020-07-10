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
# GITHUB_REPOSITORY_OWNER = username

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
    # apikey user lesson done 
    curl -s -X POST "https://learn.alem.school/api/service/grade" -H "x-grade-secret: ${1}" -H "accept: application/json" -H "Content-Type: application/json" -d "{\"username\":\"${2}\", \"lesson\":\"${3}\", \"status\": \"${4}\"}" > /dev/null
}

pip install pytest > /dev/null

for LESSON_NAME in $z
do

    # pip install -r "$SOLUTION/$LESSON_NAME/requirements.txt"
    set +e
    pytest "$SOLUTION/$LESSON_NAME"
    last="$?"
    set -e
    if [[ $last -eq 0 ]]; then
        printf "✅ $LESSON_NAME-$TEST ALL TESTS PASSED\n"
        send_result $API_KEY $GITHUB_ACTOR $LESSON_NAME-$TEST "done"
    else
        printf "🚫 TEST FAILED\n"
    fi

done

printf "👾👾👾 done 👾👾👾\n"
