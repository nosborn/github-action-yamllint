#!/bin/sh

YAMLLINT=yamllint
YAMLLINT="${YAMLLINT}${INPUT_CONFIG_FILE:+ -c ${INPUT_CONFIG_FILE}}"
YAMLLINT="${YAMLLINT}${INPUT_CONFIG_DATA:+ -d ${INPUT_CONFIG_DATA}}"
YAMLLINT="${YAMLLINT}${INPUT_STRICT:+ -s}"

# shellcheck disable=SC2086
OUTPUT=$(${YAMLLINT} -f colored ${INPUT_FILE_OR_DIR})
SUCCESS=$?
echo "${OUTPUT}"

if [ ${SUCCESS} -eq 0 ]; then
  exit 0
fi

if [ "${GITHUB_EVENT_NAME}" = pull_request ]; then
  comment=""
  FILES=$(echo "${OUTPUT}" | sed 's/\x1b\[[0-9;]*m//g' | grep '^[^[:space:]]')

  for file in ${FILES}; do
    comment="${comment}<details><summary><code>${file}</code></summary>

\`\`\`
$(${YAMLLINT} -f standard "${file}" | sed '1d;/^$/d')
\`\`\`

</details>"
  done

  COMMENT_BODY="#### Issues with YAML files
${comment}

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`*"
  PAYLOAD=$(echo '{}' | jq --arg body "${COMMENT_BODY}" '.body = $body')
  COMMENTS_URL=$(jq -r .pull_request.comments_url <"${GITHUB_EVENT_PATH}")

  curl -sS \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H 'Content-Type: application/json' \
    -d "${PAYLOAD}" \
    "${COMMENTS_URL}" >/dev/null
fi

exit ${SUCCESS}
